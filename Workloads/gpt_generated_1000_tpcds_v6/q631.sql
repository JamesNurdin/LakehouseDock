WITH store_profit AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_profit,
        'store' AS channel
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ss.ss_net_profit) > 0
),
web_profit AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_profit,
        'web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT DISTINCT year, category, channel, total_profit
FROM (
    SELECT d_year AS year, i_category AS category, total_profit, channel FROM store_profit
    UNION ALL
    SELECT d_year AS year, i_category AS category, total_profit, channel FROM web_profit
) combined
ORDER BY total_profit DESC
LIMIT 100
