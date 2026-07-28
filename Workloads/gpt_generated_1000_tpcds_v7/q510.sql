SELECT date_key,
       channel,
       total_net_paid,
       total_quantity
FROM (
    SELECT ss.ss_sold_date_sk AS date_key,
           'Store' AS channel,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_sold_date_sk

    UNION ALL

    SELECT ws.ws_sold_date_sk AS date_key,
           'Web' AS channel,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_sold_date_sk
) AS combined
ORDER BY date_key, channel
