SELECT
    t.t_hour,
    COUNT(*) AS sales_count,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM
    web_sales ws
JOIN
    time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
WHERE
    t.t_am_pm = 'PM'
    AND ws.ws_list_price > 50
GROUP BY
    t.t_hour
ORDER BY
    total_net_profit DESC
