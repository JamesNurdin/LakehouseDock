WITH catalog_agg AS (
  SELECT
    i.i_category AS category,
    SUM(cs.cs_net_profit) AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    AND cs.cs_quantity > 0
  GROUP BY i.i_category
),
web_agg AS (
  SELECT
    i.i_category AS category,
    SUM(ws.ws_net_profit) AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    AND ws.ws_quantity > 0
  GROUP BY i.i_category
)
SELECT
  category,
  SUM(net_profit) AS total_net_profit
FROM (
  SELECT category, net_profit FROM catalog_agg
  UNION ALL
  SELECT category, net_profit FROM web_agg
) u
GROUP BY category
HAVING SUM(net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
