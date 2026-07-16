SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_division_name AS store_division,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_period,
    wp.wp_type AS page_type,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(cr.cr_net_loss) AS sum_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_fee) AS sum_fee,
    SUM(wp.wp_image_count) AS sum_image_cnt,
    SUM(wp.wp_link_count) AS sum_link_cnt,
    MIN(d_access.d_year) AS earliest_access_year,
    MAX(d_access.d_year) AS latest_access_year
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cr.cr_net_loss > 0
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_division_name,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    wp.wp_type
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY sum_net_loss DESC
LIMIT 50
