WITH ws_sample AS (
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_bill_customer_sk,
        ws_net_paid_inc_tax
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
ws_with_warehouse AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_paid_inc_tax,
        wh.w_warehouse_name AS warehouse_name
    FROM ws_sample ws
    CROSS JOIN LATERAL (
        SELECT w.w_warehouse_name
        FROM warehouse w
        WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
    ) AS wh
)
SELECT
    final.customer_id,
    final.source,
    final.total_amount,
    final.first_date_sk,
    final.last_date_sk,
    final.warehouse_name
FROM (
    SELECT
        c.c_customer_id AS customer_id,
        'WebSales' AS source,
        SUM(w.ws_net_paid_inc_tax) AS total_amount,
        MIN(w.ws_sold_date_sk) AS first_date_sk,
        MAX(w.ws_sold_date_sk) AS last_date_sk,
        MAX(w.warehouse_name) AS warehouse_name
    FROM ws_with_warehouse w
    JOIN time_dim td ON w.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON w.ws_promo_sk = p.p_promo_sk
    WHERE ib.ib_lower_bound >= 120001
      AND p.p_promo_name = 'Holiday Sale'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = w.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT
        c.c_customer_id AS customer_id,
        'CatalogReturns' AS source,
        -SUM(cr.cr_net_loss) AS total_amount,
        MIN(cr.cr_returned_date_sk) AS first_date_sk,
        MAX(cr.cr_returned_date_sk) AS last_date_sk,
        CAST(NULL AS varchar) AS warehouse_name
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 150000
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_warehouse_sk = cr.cr_warehouse_sk
            AND w.w_gmt_offset IS NOT NULL
      )
    GROUP BY c.c_customer_id
) AS final
ORDER BY final.total_amount DESC
LIMIT 100
