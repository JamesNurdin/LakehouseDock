WITH inv_agg AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
),
base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cp.cp_department,
        p.p_promo_name,
        wp.wp_url,
        ws.web_name,
        inv_agg.total_qty_on_hand,
        r.r_reason_desc,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price,
        sr.sr_refunded_cash,
        d.d_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Books'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr2
            JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND r2.r_reason_desc = 'Damaged'
        )
)
SELECT
    s_store_name,
    s_state,
    d_year,
    d_month_seq,
    t_hour,
    cp_department,
    p_promo_name,
    wp_url,
    web_name,
    total_qty_on_hand,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(sr_refunded_cash) AS total_refunded_cash,
    MAX(r_reason_desc) AS any_return_reason,
    (SELECT AVG(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_sold_date_sk = d_date_sk) AS avg_daily_catalog_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_ext_sales_price) + SUM(ss_ext_sales_price) DESC) AS sales_rank,
    CASE WHEN SUM(cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Medium' END AS sales_category
FROM base
GROUP BY
    s_store_name,
    s_state,
    d_year,
    d_month_seq,
    t_hour,
    cp_department,
    p_promo_name,
    wp_url,
    web_name,
    total_qty_on_hand,
    d_date_sk
ORDER BY total_catalog_sales DESC
LIMIT 100
