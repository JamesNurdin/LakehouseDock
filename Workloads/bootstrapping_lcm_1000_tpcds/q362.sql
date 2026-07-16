SELECT
    d_return.d_year AS return_year,
    d_start.d_month_seq AS page_start_month,
    d_end.d_month_seq AS page_end_month,
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    s.s_city,
    CASE WHEN cp.cp_type = 'PROMO' THEN 'Promo' ELSE 'Standard' END AS page_category,
    (cp.cp_catalog_number % 10) AS catalog_number_bucket,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_quantity,
    AVG(wr.wr_return_quantity) AS avg_web_return_quantity,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_return.d_year,
    d_start.d_month_seq,
    d_end.d_month_seq,
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    s.s_city,
    CASE WHEN cp.cp_type = 'PROMO' THEN 'Promo' ELSE 'Standard' END,
    (cp.cp_catalog_number % 10)
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_catalog_return_amount DESC
LIMIT 100
