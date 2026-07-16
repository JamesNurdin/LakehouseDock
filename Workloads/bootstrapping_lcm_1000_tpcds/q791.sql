SELECT
    cp.cp_department,
    dr.d_year,
    s.s_state,
    wp.wp_type,
    (dr.d_year * 100 + d_end.d_month_seq) AS year_month,
    CASE
        WHEN s.s_state IN ('CA','OR','WA') THEN 'West'
        WHEN s.s_state IN ('NY','NJ','CT') THEN 'East'
        ELSE 'Other'
    END AS region,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_positive_net_loss,
    SUM(CASE WHEN cr.cr_net_loss < 0 THEN cr.cr_net_loss ELSE 0 END) AS total_negative_net_loss,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0), 2) AS avg_return_amount_per_qty,
    MAX(d_end.d_date) AS max_end_date,
    MIN(d_start.d_date) AS min_start_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_image_count * wp.wp_link_count) AS total_image_link_product
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_end.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    cp.cp_department,
    dr.d_year,
    s.s_state,
    wp.wp_type,
    (dr.d_year * 100 + d_end.d_month_seq),
    CASE
        WHEN s.s_state IN ('CA','OR','WA') THEN 'West'
        WHEN s.s_state IN ('NY','NJ','CT') THEN 'East'
        ELSE 'Other'
    END
ORDER BY total_return_amount DESC
LIMIT 100
