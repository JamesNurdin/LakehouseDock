WITH combined AS (
  SELECT
    dd.d_year,
    dd.d_moy,
    it.i_category,
    cs.cs_net_profit AS net_profit,
    'catalog' AS channel
  FROM catalog_sales cs
  JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
  JOIN item it ON cs.cs_item_sk = it.i_item_sk

  UNION ALL

  SELECT
    dd.d_year,
    dd.d_moy,
    it.i_category,
    ss.ss_net_profit AS net_profit,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN item it ON ss.ss_item_sk = it.i_item_sk

  UNION ALL

  SELECT
    dd.d_year,
    dd.d_moy,
    it.i_category,
    ws.ws_net_profit AS net_profit,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
  JOIN item it ON ws.ws_item_sk = it.i_item_sk

  UNION ALL

  SELECT
    dd.d_year,
    dd.d_moy,
    it.i_category,
    -sr.sr_net_loss AS net_profit,
    'return' AS channel
  FROM store_returns sr
  JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
  JOIN item it ON sr.sr_item_sk = it.i_item_sk
)
SELECT
  d_year AS year,
  d_moy AS month,
  i_category AS category,
  SUM(CASE WHEN channel = 'return' THEN 0 ELSE net_profit END) AS total_sales_net_profit,
  SUM(CASE WHEN channel = 'return' THEN -net_profit ELSE 0 END) AS total_returns_net_loss,
  SUM(net_profit) AS net_profit_after_returns
FROM combined
WHERE d_year = 2001
GROUP BY d_year, d_moy, i_category
ORDER BY d_year, d_moy, i_category
