SELECT
    d.d_year,
    d.d_month_seq,
    w.w_state,
    s.s_state,
    floor(cr.cr_return_amount / 1000) AS amount_bucket,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(cr.cr_fee) AS total_fee,
    AVG(cr.cr_return_quantity) AS avg_qty_returned,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_created_pages,
    COUNT(DISTINCT wp2.wp_web_page_sk) AS distinct_accessed_pages,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_creations,
    SUM(CASE WHEN wp2.wp_type = 'category' THEN 1 ELSE 0 END) AS category_page_accesses
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_page wp2
    ON wp2.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND w.w_gmt_offset IS NOT NULL
  AND s.s_market_id > 0
GROUP BY
    d.d_year,
    d.d_month_seq,
    w.w_state,
    s.s_state,
    floor(cr.cr_return_amount / 1000)
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
