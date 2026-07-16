SELECT
    dr.d_date AS return_date,
    od.d_date AS call_center_open_date,
    date_diff('day', od.d_date, dr.d_date) AS days_since_center_open,
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    wp.wp_url AS web_page_url,
    dp_creation.d_date AS page_creation_date,
    dp_access.d_date AS page_access_date,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    AVG(wr.wr_return_tax) AS avg_return_tax
FROM web_returns wr
JOIN date_dim dr
    ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dp_creation
    ON wp.wp_creation_date_sk = dp_creation.d_date_sk
JOIN date_dim dp_access
    ON wp.wp_access_date_sk = dp_access.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = dr.d_date_sk
JOIN date_dim od
    ON cc.cc_open_date_sk = od.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
GROUP BY
    dr.d_date,
    od.d_date,
    cc.cc_name,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    wp.wp_url,
    dp_creation.d_date,
    dp_access.d_date
ORDER BY total_return_amount DESC
LIMIT 100
