SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_description,
    dd_start.d_date AS start_date,
    dd_end.d_date AS end_date,
    dd_end.d_year,
    dd_end.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    COUNT(DISTINCT wr.wr_order_number) AS num_return_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    MAX(wp.wp_image_count) AS max_image_count
FROM catalog_page cp
JOIN date_dim dd_end
    ON cp.cp_end_date_sk = dd_end.d_date_sk
JOIN date_dim dd_start
    ON cp.cp_start_date_sk = dd_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dd_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd_end.d_date_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cp.cp_type = 'Seasonal'
  AND s.s_state = 'CA'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_description,
    dd_start.d_date,
    dd_end.d_date,
    dd_end.d_year,
    dd_end.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count
ORDER BY total_return_amount DESC
LIMIT 100
