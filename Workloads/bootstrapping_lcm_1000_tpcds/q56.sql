SELECT
    d_main.d_date AS return_date,
    d_main.d_year,
    d_main.d_month_seq,
    t.t_hour,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    s.s_state,
    p.p_channel_tv,
    p.p_promo_name,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS sum_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS sum_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS sum_net_loss,
    SUM(wr.wr_return_quantity) AS sum_return_qty,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items,
    (SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0)) AS avg_return_per_qty,
    (SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0)) AS loss_ratio,
    DATE_DIFF('day', d_main.d_date, d_end.d_date) AS promo_duration_days
FROM date_dim d_main
JOIN web_returns wr ON wr.wr_returned_date_sk = d_main.d_date_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
JOIN store s ON s.s_closed_date_sk = d_main.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_main.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_main.d_year BETWEEN 2020 AND 2022
  AND s.s_state IS NOT NULL
  AND p.p_channel_tv IS NOT NULL
GROUP BY
    d_main.d_date,
    d_main.d_year,
    d_main.d_month_seq,
    t.t_hour,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    s.s_state,
    p.p_channel_tv,
    p.p_promo_name,
    d_end.d_date
HAVING COUNT(*) > 5
ORDER BY sum_net_loss DESC
LIMIT 200
