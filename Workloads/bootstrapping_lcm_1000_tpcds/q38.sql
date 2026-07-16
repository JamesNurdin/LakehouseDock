SELECT
    s.s_store_name,
    d_return.d_current_month,
    CASE WHEN t.t_hour < 12 THEN 'Morning' ELSE 'Afternoon' END AS time_of_day,
    wp.wp_type,
    COUNT(*) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(sr.sr_return_quantity) AS total_quantity,
    AVG(date_diff('day', d_return.d_date, d_access.d_date)) AS avg_days_between_return_and_access,
    SUM(CASE WHEN sr.sr_return_amt > 100 THEN 1 ELSE 0 END) AS high_value_return_cnt
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_closed.d_date_sk IS NULL
  AND d_access.d_year = 2022
GROUP BY
    s.s_store_name,
    d_return.d_current_month,
    CASE WHEN t.t_hour < 12 THEN 'Morning' ELSE 'Afternoon' END,
    wp.wp_type
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
