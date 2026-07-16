SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_market_desc,
    i.i_category,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt / NULLIF(wr.wr_return_quantity, 0)) AS avg_return_per_item,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_market_desc,
    i.i_category,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
