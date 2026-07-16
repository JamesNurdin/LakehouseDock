SELECT
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month,
    cp.cp_type,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT s.s_store_id) AS distinct_store_count,
    MIN(d_start.d_date) AS catalog_start_date,
    MAX(d_end.d_date) AS catalog_end_date,
    CASE
        WHEN SUM(cr.cr_return_amount) > 20000 THEN 'VERY HIGH'
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH'
        WHEN SUM(cr.cr_return_amount) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_category
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_year >= 2020
  AND cp.cp_type IS NOT NULL
GROUP BY
    d_ret.d_year * 100 + d_ret.d_month_seq,
    cp.cp_type,
    s.s_state
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY year_month DESC, cp.cp_type
LIMIT 100
