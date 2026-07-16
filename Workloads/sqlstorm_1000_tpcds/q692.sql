WITH agg AS (
  SELECT
    dd.d_year,
    i.i_category,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_net_paid) AS total_sales
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE dd.d_year BETWEEN 1999 AND 2002
  GROUP BY dd.d_year, i.i_category
  UNION ALL
  SELECT
    dd.d_year,
    i.i_category,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_paid) AS total_sales
  FROM web_sales ws
  JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE dd.d_year BETWEEN 1999 AND 2002
  GROUP BY dd.d_year, i.i_category
  UNION ALL
  SELECT
    dd.d_year,
    i.i_category,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_net_paid) AS total_sales
  FROM catalog_sales cs
  JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE dd.d_year BETWEEN 1999 AND 2002
  GROUP BY dd.d_year, i.i_category
), ranked AS (
  SELECT
    d_year,
    i_category,
    channel,
    total_profit,
    total_sales,
    total_profit / total_sales AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rank_per_year
  FROM agg
)
SELECT
  d_year,
  i_category,
  channel,
  total_profit,
  total_sales,
  profit_margin
FROM ranked
WHERE rank_per_year <= 10
ORDER BY d_year, rank_per_year
