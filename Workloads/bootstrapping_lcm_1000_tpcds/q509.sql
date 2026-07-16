SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    d_start.d_date AS start_date,
    d_end.d_date AS end_date,
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_day_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT s.s_store_id) AS closed_store_cnt,
    COUNT(DISTINCT wp_create.wp_web_page_id) AS created_pages_cnt,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS accessed_pages_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
LEFT JOIN web_page wp_create
    ON wp_create.wp_creation_date_sk = d_return.d_date_sk
LEFT JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d_return.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    d_start.d_date,
    d_end.d_date,
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_day_name
ORDER BY total_return_amount DESC
LIMIT 100
