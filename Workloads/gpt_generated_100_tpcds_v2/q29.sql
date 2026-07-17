WITH catalog_sales_agg AS (
  SELECT
    i.i_item_id,
    d.d_year,
    'catalog' AS channel,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
  GROUP BY i.i_item_id, d.d_year
),
web_sales_agg AS (
  SELECT
    i.i_item_id,
    d.d_year,
    'web' AS channel,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
  GROUP BY i.i_item_id, d.d_year
)
SELECT i_item_id, d_year, channel, total_net_paid, total_net_profit
FROM catalog_sales_agg
UNION ALL
SELECT i_item_id, d_year, channel, total_net_paid, total_net_profit
FROM web_sales_agg
ORDER BY i_item_id, d_year, channel
