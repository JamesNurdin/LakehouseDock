WITH filtered_time AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_hour BETWEEN 9 AND 17
)
SELECT
    'catalog' AS source,
    cs.cs_item_sk AS item_sk,
    cs.cs_sold_date_sk AS sold_date_sk,
    SUM(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN filtered_time ft ON cs.cs_sold_time_sk = ft.t_time_sk
WHERE cs.cs_net_profit > 0
GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk

UNION ALL

SELECT
    'store' AS source,
    ss.ss_item_sk AS item_sk,
    ss.ss_sold_date_sk AS sold_date_sk,
    SUM(ss.ss_net_profit) AS total_profit
FROM store_sales ss
JOIN filtered_time ft ON ss.ss_sold_time_sk = ft.t_time_sk
WHERE ss.ss_net_profit > 0
GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk

ORDER BY total_profit DESC
LIMIT 100
