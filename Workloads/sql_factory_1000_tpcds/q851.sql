WITH cs_agg AS (
    SELECT cs_sold_time_sk,
           SUM(cs_net_profit) AS catalog_profit,
           SUM(cs_quantity) AS catalog_quantity
    FROM catalog_sales
    GROUP BY cs_sold_time_sk
),
ws_agg AS (
    SELECT ws_sold_time_sk,
           SUM(ws_net_profit) AS web_profit,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_sold_time_sk
)
SELECT
    t.t_hour,
    t.t_am_pm,
    cs_agg.catalog_profit,
    ws_agg.web_profit,
    cs_agg.catalog_quantity,
    ws_agg.web_quantity,
    cs_agg.catalog_profit - ws_agg.web_profit AS profit_diff,
    RANK() OVER (ORDER BY cs_agg.catalog_profit DESC) AS catalog_profit_rank,
    CASE
        WHEN cs_agg.catalog_profit > ws_agg.web_profit THEN 'Catalog Higher'
        WHEN cs_agg.catalog_profit < ws_agg.web_profit THEN 'Web Higher'
        ELSE 'Equal'
    END AS profit_comparison
FROM time_dim t
LEFT JOIN cs_agg ON cs_agg.cs_sold_time_sk = t.t_time_sk
LEFT JOIN ws_agg ON ws_agg.ws_sold_time_sk = t.t_time_sk
WHERE t.t_hour IS NOT NULL
ORDER BY t.t_hour, t.t_am_pm
