SELECT
    d_return.d_year,
    d_return.d_month_seq,
    store.s_store_id,
    store.s_store_name,
    store.s_state,
    time_dim.t_shift,
    time_dim.t_hour,
    web_page.wp_type,
    CASE WHEN web_page.wp_char_count > 10000 THEN 'Large' ELSE 'Small' END AS page_size_category,
    date_diff('day', d_creation.d_date, d_access.d_date) AS page_lifecycle_days,
    COUNT(*) AS return_count,
    SUM(web_returns.wr_return_amt_inc_tax) AS total_return_amount,
    AVG(web_returns.wr_fee) AS avg_fee,
    SUM(web_returns.wr_net_loss) AS total_net_loss
FROM web_returns
JOIN date_dim AS d_return
    ON web_returns.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim
    ON web_returns.wr_returned_time_sk = time_dim.t_time_sk
JOIN web_page
    ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
JOIN store
    ON store.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim AS d_creation
    ON web_page.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim AS d_access
    ON web_page.wp_access_date_sk = d_access.d_date_sk
WHERE d_return.d_year BETWEEN 2018 AND 2020
  AND time_dim.t_am_pm = 'PM'
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    store.s_store_id,
    store.s_store_name,
    store.s_state,
    time_dim.t_shift,
    time_dim.t_hour,
    web_page.wp_type,
    CASE WHEN web_page.wp_char_count > 10000 THEN 'Large' ELSE 'Small' END,
    date_diff('day', d_creation.d_date, d_access.d_date)
ORDER BY total_return_amount DESC
LIMIT 100
