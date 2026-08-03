WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_warehouse_sk,
        cr.cr_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_warehouse_sk,
        inv.inv_quantity_on_hand,
        i.i_item_sk,
        i.i_product_name,
        i.i_class,
        w.w_warehouse_sk,
        w.w_county,
        cc.cc_name,
        s.s_store_name,
        d_ret.d_year AS return_year,
        d_sales.d_year AS sales_year
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON cr.cr_item_sk = ws.ws_item_sk
                       AND cr.cr_warehouse_sk = ws.ws_warehouse_sk
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d_ret.d_year = 2001
      AND i.i_class = 'furniture'
      AND w.w_county = 'Williamson County'
),
agg AS (
    SELECT
        i_item_sk,
        i_product_name,
        w_warehouse_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_sales_net,
        AVG(inv_quantity_on_hand) AS avg_inventory_qty,
        CASE WHEN SUM(ws_net_paid) = 0 THEN 0
             ELSE SUM(cr_return_amount) / SUM(ws_net_paid) END AS return_to_sales_ratio
    FROM base
    GROUP BY i_item_sk, i_product_name, w_warehouse_sk
)
SELECT
    a.i_item_sk,
    a.i_product_name,
    a.w_warehouse_sk,
    a.total_return_amount,
    a.total_sales_net,
    a.return_to_sales_ratio,
    CASE WHEN a.return_to_sales_ratio > 0.1 THEN 'High' ELSE 'Low' END AS risk_category,
    (
        SELECT COUNT(DISTINCT c.c_customer_sk)
        FROM catalog_returns cr2
        JOIN customer c ON cr2.cr_refunded_customer_sk = c.c_customer_sk
        WHERE cr2.cr_item_sk = a.i_item_sk
          AND cr2.cr_warehouse_sk = a.w_warehouse_sk
    ) AS distinct_refunded_customers,
    lt.lateral_total_return * 1.05 AS projected_return_amount
FROM agg a
LEFT JOIN LATERAL (
    SELECT SUM(cr_return_amount) AS lateral_total_return
    FROM catalog_returns cr3
    WHERE cr3.cr_item_sk = a.i_item_sk
      AND cr3.cr_warehouse_sk = a.w_warehouse_sk
) lt ON true
WHERE a.avg_inventory_qty > 50
  AND a.return_to_sales_ratio IS NOT NULL
  AND EXISTS (
        SELECT 1
        FROM store st
        WHERE st.s_store_name = 'Central Store'
          AND st.s_state = 'CA'
    )
ORDER BY a.return_to_sales_ratio DESC
LIMIT 100
