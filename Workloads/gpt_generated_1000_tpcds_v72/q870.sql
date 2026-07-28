WITH store_aggr AS (
    SELECT
        'store' AS channel,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
),
web_aggr AS (
    SELECT
        'web' AS channel,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
)
SELECT DISTINCT
    t.channel,
    t.category,
    t.total_net_profit,
    t.profit_level
FROM (
    SELECT * FROM store_aggr
    UNION ALL
    SELECT * FROM web_aggr
) t
ORDER BY t.total_net_profit DESC
LIMIT 100
