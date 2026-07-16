SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    p.p_discount_active
HAVING SUM(wr.wr_return_amt) > 0
ORDER BY total_return_amount DESC
LIMIT 100
