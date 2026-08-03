WITH store_channel AS (
    SELECT
        s.s_city AS city,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High'
            WHEN SUM(ss.ss_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_level,
        'Store' AS channel
    FROM store_sales AS ss
    JOIN store AS s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item AS i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim AS td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND s.s_city IN ('Glendale', 'Highland Park')
    GROUP BY s.s_city, i.i_category
),
web_channel AS (
    SELECT
        ws_site.web_city AS city,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High'
            WHEN SUM(ws.ws_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_level,
        'Web' AS channel
    FROM web_sales AS ws
    JOIN web_site AS ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item AS i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim AS td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND ws_site.web_state = 'NY'
    GROUP BY ws_site.web_city, i.i_category
)
SELECT * FROM store_channel
UNION ALL
SELECT * FROM web_channel
ORDER BY total_profit DESC
LIMIT 100
