WITH
store_sales_agg AS (
 SELECT
   i.i_category AS category,
   s.s_state AS state,
   d.d_year AS year,
   SUM(ss.ss_net_profit) AS profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY i.i_category, s.s_state, d.d_year
),
catalog_sales_agg AS (
 SELECT
   i.i_category AS category,
   cc.cc_state AS state,
   d.d_year AS year,
   SUM(cs.cs_net_profit) AS profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY i.i_category, cc.cc_state, d.d_year
),
web_sales_agg AS (
 SELECT
   i.i_category AS category,
   w.web_state AS state,
   d.d_year AS year,
   SUM(ws.ws_net_profit) AS profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY i.i_category, w.web_state, d.d_year
)
SELECT
  category,
  state,
  year,
  SUM(profit) AS total_profit
FROM (
  SELECT category, state, year, profit FROM store_sales_agg
  UNION ALL
  SELECT category, state, year, profit FROM catalog_sales_agg
  UNION ALL
  SELECT category, state, year, profit FROM web_sales_agg
) t
GROUP BY category, state, year
ORDER BY total_profit DESC
LIMIT 100
