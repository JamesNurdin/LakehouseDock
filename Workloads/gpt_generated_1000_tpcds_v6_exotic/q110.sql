WITH store_agg AS (
    SELECT
        s.s_store_id AS channel_id,
        i.i_class AS item_class,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_class = 'costume'
    GROUP BY s.s_store_id, i.i_class
    HAVING SUM(ss.ss_net_profit) > 0
),
web_agg AS (
    SELECT
        CAST(ws.ws_web_site_sk AS VARCHAR) AS channel_id,
        i.i_class AS item_class,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_class = 'costume'
    GROUP BY ws.ws_web_site_sk, i.i_class
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    channel_id,
    item_class,
    total_profit,
    profit_flag
FROM store_agg
UNION ALL
SELECT
    channel_id,
    item_class,
    total_profit,
    profit_flag
FROM web_agg
ORDER BY total_profit DESC
LIMIT 100
