WITH sales AS (
   SELECT
       ws.ws_web_site_sk,
       d.d_year,
       SUM(ws.ws_net_profit) AS total_sales_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE d.d_year = 2000
     AND wsite.web_tax_percentage > 0.05
     AND ws.ws_list_price BETWEEN 50 AND 200
   GROUP BY ws.ws_web_site_sk, d.d_year
),
store_ret AS (
   SELECT
       ws.ws_web_site_sk,
       d.d_year,
       SUM(sr.sr_net_loss) AS total_store_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_sold_time_sk = t.t_time_sk
   WHERE sr.sr_reason_sk IN (7, 19)
   GROUP BY ws.ws_web_site_sk, d.d_year
),
web_ret AS (
   SELECT
       ws.ws_web_site_sk,
       d.d_year,
       SUM(wr.wr_net_loss) AS total_web_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
   GROUP BY ws.ws_web_site_sk, d.d_year
)
SELECT
   s.ws_web_site_sk,
   wsite.web_name,
   s.d_year,
   s.total_sales_profit,
   COALESCE(sr.total_store_loss, 0) AS total_store_loss,
   COALESCE(wr.total_web_loss, 0) AS total_web_loss,
   (s.total_sales_profit - COALESCE(sr.total_store_loss, 0) - COALESCE(wr.total_web_loss, 0)) AS net_combined,
   RANK() OVER (PARTITION BY s.d_year ORDER BY (s.total_sales_profit - COALESCE(sr.total_store_loss, 0) - COALESCE(wr.total_web_loss, 0)) DESC) AS profit_rank,
   CASE
       WHEN (s.total_sales_profit - COALESCE(sr.total_store_loss, 0) - COALESCE(wr.total_web_loss, 0)) > 10000 THEN 'HIGH'
       WHEN (s.total_sales_profit - COALESCE(sr.total_store_loss, 0) - COALESCE(wr.total_web_loss, 0)) BETWEEN 0 AND 10000 THEN 'MEDIUM'
       ELSE 'LOW'
   END AS profitability_category
FROM sales s
LEFT JOIN store_ret sr ON s.ws_web_site_sk = sr.ws_web_site_sk AND s.d_year = sr.d_year
LEFT JOIN web_ret wr ON s.ws_web_site_sk = wr.ws_web_site_sk AND s.d_year = wr.d_year
JOIN web_site wsite ON s.ws_web_site_sk = wsite.web_site_sk
ORDER BY net_combined DESC
LIMIT 100
