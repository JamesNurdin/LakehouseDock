WITH catalog_profit AS (
    SELECT
        td.t_hour AS hour,
        cc.cc_name AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour, cc.cc_name
),
web_profit AS (
    SELECT
        td.t_hour AS hour,
        'Web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour
)
SELECT hour, channel, total_net_profit
FROM catalog_profit
UNION ALL
SELECT hour, channel, total_net_profit
FROM web_profit
ORDER BY hour ASC, channel ASC
LIMIT 100
