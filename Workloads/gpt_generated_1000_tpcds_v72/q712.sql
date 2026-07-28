WITH cs AS (
  SELECT
    i.i_brand AS brand,
    i.i_item_desc AS item_desc,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(cs.cs_net_profit) >= 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(cs.cs_net_profit) DESC) AS brand_rank
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_brand, i.i_item_desc
  HAVING SUM(cs.cs_net_profit) > 1000
),
ws AS (
  SELECT
    i.i_brand AS brand,
    i.i_item_desc AS item_desc,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE WHEN SUM(ws.ws_net_profit) >= 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ws.ws_net_profit) DESC) AS brand_rank
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_brand, i.i_item_desc
  HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
  sales_channel,
  brand,
  item_desc,
  total_profit,
  sales_cnt,
  profit_flag,
  brand_rank
FROM (
  SELECT 'Catalog' AS sales_channel, brand, item_desc, total_profit, sales_cnt, profit_flag, brand_rank
  FROM cs
  UNION ALL
  SELECT 'Web' AS sales_channel, brand, item_desc, total_profit, sales_cnt, profit_flag, brand_rank
  FROM ws
) combined
ORDER BY brand, total_profit DESC
LIMIT 100
