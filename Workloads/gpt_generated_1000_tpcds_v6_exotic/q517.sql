WITH store_sales_filtered AS (
   SELECT
       d.d_year AS year,
       'store' AS channel,
       ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
     AND NOT EXISTS (
         SELECT 1 FROM store_returns sr
         WHERE sr.sr_item_sk = ss.ss_item_sk
     )
),
catalog_sales_filtered AS (
   SELECT
       d.d_year AS year,
       'catalog' AS channel,
       cs.cs_net_profit AS net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
     AND NOT EXISTS (
         SELECT 1 FROM catalog_returns cr
         WHERE cr.cr_item_sk = cs.cs_item_sk
     )
)
SELECT
    year,
    channel,
    SUM(net_profit) AS total_net_profit,
    SUM(CASE WHEN net_profit > 0 THEN net_profit ELSE 0 END) AS positive_net_profit
FROM (
    SELECT year, channel, net_profit FROM store_sales_filtered
    UNION ALL
    SELECT year, channel, net_profit FROM catalog_sales_filtered
) AS combined
GROUP BY GROUPING SETS ((year, channel), (year), ())
ORDER BY year, channel
LIMIT 100
