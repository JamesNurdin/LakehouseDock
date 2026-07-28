WITH store AS (
    SELECT i.i_item_id AS item_id,
           SUM(ss.ss_net_profit) AS net_profit,
           CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_id
),
web AS (
    SELECT i.i_item_id AS item_id,
           SUM(ws.ws_net_profit) AS net_profit,
           CAST('web' AS varchar) AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 12
    GROUP BY i.i_item_id
)
SELECT DISTINCT item_id,
                net_profit,
                channel
FROM (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM web
) AS combined
ORDER BY item_id,
         channel
