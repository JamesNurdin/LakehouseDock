WITH base AS (
    SELECT
        s.s_store_name,
        w.w_warehouse_name,
        r.r_reason_desc,
        d_sr.d_date,
        sr.sr_return_amt_inc_tax,
        cr.cr_return_amount,
        sr.sr_customer_sk,
        i.inv_quantity_on_hand
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d_sr.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year = 2001
      AND s.s_state = 'CA'
      AND w.w_gmt_offset = -5.00
      AND r.r_reason_desc = 'Damaged'
      AND ws.web_country = 'United States'
)
SELECT
    b.s_store_name,
    b.w_warehouse_name,
    b.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(b.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(b.cr_return_amount) AS avg_catalog_return,
    COUNT(DISTINCT b.sr_customer_sk) AS unique_customers,
    MIN(b.d_date) AS first_return_date,
    SUM(b.inv_quantity_on_hand) AS total_inventory_on_hand,
    (SELECT COUNT(DISTINCT cr_order_number) FROM catalog_returns) AS total_distinct_orders
FROM base b
GROUP BY b.s_store_name, b.w_warehouse_name, b.r_reason_desc
ORDER BY total_return_inc_tax DESC
LIMIT 100
