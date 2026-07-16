SELECT
    c.cc_division,
    c.cc_division_name,
    s.s_state,
    s.s_city,
    wp.wp_type,
    d_wr_returned.d_year,
    d_wr_returned.d_month_seq,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wr.wr_return_tax > 0 THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS total_taxed_return_amount,
    SUM(CASE WHEN wr.wr_fee > 0 THEN wr.wr_fee ELSE 0 END) AS total_fees,
    AVG(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_quantity END) AS avg_quantity_nonzero,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    AVG(date_diff('day', d_cc_open.d_date, d_cc_closed.d_date)) AS avg_call_center_lifespan_days,
    SUM(s.s_floor_space) AS total_store_floor_space,
    SUM(wr.wr_return_amt) / NULLIF(SUM(s.s_floor_space), 0) AS return_per_sqft,
    AVG(date_diff('day', d_wp_creation.d_date, d_wp_access.d_date)) AS avg_page_age_days
FROM call_center c
JOIN date_dim d_cc_closed
    ON c.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON c.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
CROSS JOIN web_returns wr
JOIN date_dim d_wr_returned
    ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    c.cc_division,
    c.cc_division_name,
    s.s_state,
    s.s_city,
    wp.wp_type,
    d_wr_returned.d_year,
    d_wr_returned.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
