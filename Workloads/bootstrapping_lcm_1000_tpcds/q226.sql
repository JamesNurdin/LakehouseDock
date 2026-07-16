SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date,
    COUNT(DISTINCT cr.cr_order_number) AS returns_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
    SUM(CASE WHEN d_access.d_date = d_ret.d_date THEN 1 ELSE 0 END) AS pages_accessed_on_return_date,
    MIN(t.t_time) AS earliest_return_time,
    MAX(t.t_time) AS latest_return_time
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
WHERE d_ret.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date
ORDER BY total_net_loss DESC
LIMIT 100
