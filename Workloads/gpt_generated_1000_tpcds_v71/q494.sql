WITH
  store_agg AS (
    SELECT
      d.d_year AS year,
      'store' AS channel,
      SUM(ss.ss_net_paid) AS total_net_paid,
      SUM(ss.ss_net_profit) AS total_net_profit,
      CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
  ),
  web_agg AS (
    SELECT
      d.d_year AS year,
      'web' AS channel,
      SUM(ws.ws_net_paid) AS total_net_paid,
      SUM(ws.ws_net_profit) AS total_net_profit,
      CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
  )
SELECT
  year,
  channel,
  total_net_paid,
  total_net_profit,
  sales_level
FROM (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
) AS combined
ORDER BY year DESC, total_net_paid DESC
LIMIT 100
