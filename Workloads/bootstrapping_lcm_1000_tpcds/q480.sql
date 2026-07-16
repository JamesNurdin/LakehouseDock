SELECT
    s.s_city,
    s.s_state,
    d_store.d_year AS store_closed_year,
    d_store.d_month_seq AS store_closed_month,
    cp.cp_type,
    cp.cp_description,
    cp.cp_catalog_number,
    d_cp_start.d_year AS catalog_start_year,
    d_cp_end.d_year AS catalog_end_year,
    d_cr.d_year AS catalog_return_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_store
    ON cp.cp_end_date_sk = d_store.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_cr.d_date_sk
GROUP BY
    s.s_city,
    s.s_state,
    d_store.d_year,
    d_store.d_month_seq,
    cp.cp_type,
    cp.cp_description,
    cp.cp_catalog_number,
    d_cp_start.d_year,
    d_cp_end.d_year,
    d_cr.d_year
ORDER BY total_catalog_return_amount DESC
LIMIT 100
