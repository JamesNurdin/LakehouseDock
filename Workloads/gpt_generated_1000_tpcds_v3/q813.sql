WITH warehouse_pattern AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        CASE
            WHEN regexp_like(w.w_warehouse_name, '(?i)issues') THEN 'Issues'
            WHEN regexp_like(w.w_warehouse_name, '(?i)cook') THEN 'Cook'
            ELSE 'Other'
        END AS warehouse_category,
        regexp_extract(w.w_warehouse_name, '([A-Za-z]+)', 1) AS first_word,
        concat(w.w_street_number, ' ', w.w_street_name) AS full_address
    FROM warehouse w
)
SELECT
    dr.d_year,
    dr.d_month_seq,
    wp.warehouse_category,
    wp.first_word,
    COUNT(cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_returns
FROM catalog_returns cr
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN warehouse_pattern wp
    ON cr.cr_warehouse_sk = wp.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dr.d_date_sk
WHERE wp.warehouse_category <> 'Other'
  AND s.s_store_name LIKE '%Store%'
GROUP BY dr.d_year, dr.d_month_seq, wp.warehouse_category, wp.first_word
ORDER BY total_return_amount DESC
LIMIT 100
