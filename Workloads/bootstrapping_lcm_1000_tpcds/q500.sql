SELECT
    cp.cp_department,
    cp.cp_type,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_start.d_month_seq AS start_month_seq,
    d_end.d_month_seq   AS end_month_seq,
    COUNT(DISTINCT cr.cr_order_number)   AS order_cnt,
    SUM(cr.cr_return_amount)             AS total_return_amount,
    SUM(cr.cr_net_loss)                  AS total_net_loss,
    AVG(cr.cr_return_quantity)           AS avg_return_qty,
    COUNT(DISTINCT s.s_store_id)         AS closed_store_cnt,
    COUNT(DISTINCT wp.wp_web_page_id)    AS web_page_cnt,
    SUM(wp.wp_image_count)               AS total_wp_images,
    SUM(wp.wp_link_count)                AS total_wp_links
FROM catalog_returns cr
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_start
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access
  ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND cp.cp_type IN ('A', 'B')
GROUP BY
    cp.cp_department,
    cp.cp_type,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_start.d_month_seq,
    d_end.d_month_seq
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
