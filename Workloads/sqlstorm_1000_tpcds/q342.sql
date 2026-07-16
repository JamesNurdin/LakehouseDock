WITH
catalog_sales_agg AS (
 SELECT
   d.d_date_sk AS date_sk,
   d.d_date AS sold_date,
   SUM(cs.cs_net_profit) AS cat_net_profit,
   SUM(cs.cs_quantity) AS cat_quantity,
   COUNT(DISTINCT cs.cs_order_number) AS cat_orders
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 GROUP BY d.d_date_sk, d.d_date
),
store_sales_agg AS (
 SELECT
   d.d_date_sk AS date_sk,
   d.d_date AS sold_date,
   SUM(ss.ss_net_profit) AS store_net_profit,
   SUM(ss.ss_quantity) AS store_quantity,
   COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 GROUP BY d.d_date_sk, d.d_date
),
web_sales_agg AS (
 SELECT
   d.d_date_sk AS date_sk,
   d.d_date AS sold_date,
   SUM(ws.ws_net_profit) AS web_net_profit,
   SUM(ws.ws_quantity) AS web_quantity,
   COUNT(DISTINCT ws.ws_order_number) AS web_orders
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 GROUP BY d.d_date_sk, d.d_date
),
combined_sales AS (
 SELECT
   COALESCE(csd.date_sk, ssd.date_sk, wsd.date_sk) AS date_sk,
   COALESCE(csd.sold_date, ssd.sold_date, wsd.sold_date) AS sold_date,
   COALESCE(csd.cat_net_profit, 0) AS cat_net_profit,
   COALESCE(ssd.store_net_profit, 0) AS store_net_profit,
   COALESCE(wsd.web_net_profit, 0) AS web_net_profit,
   COALESCE(csd.cat_quantity, 0) AS cat_quantity,
   COALESCE(ssd.store_quantity, 0) AS store_quantity,
   COALESCE(wsd.web_quantity, 0) AS web_quantity,
   COALESCE(csd.cat_orders, 0) AS cat_orders,
   COALESCE(ssd.store_orders, 0) AS store_orders,
   COALESCE(wsd.web_orders, 0) AS web_orders
 FROM catalog_sales_agg csd
 FULL OUTER JOIN store_sales_agg ssd ON csd.date_sk = ssd.date_sk
 FULL OUTER JOIN web_sales_agg wsd ON COALESCE(csd.date_sk, ssd.date_sk) = wsd.date_sk
),
sales_stats AS (
 SELECT
   date_sk,
   sold_date,
   cat_net_profit,
   store_net_profit,
   web_net_profit,
   cat_quantity,
   store_quantity,
   web_quantity,
   cat_orders,
   store_orders,
   web_orders,
   (cat_net_profit + store_net_profit + web_net_profit) AS total_net_profit,
   SUM(cat_net_profit + store_net_profit + web_net_profit) OVER (
     ORDER BY sold_date
     ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
   ) / NULLIF(COUNT(*) OVER (
     ORDER BY sold_date
     ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
   ), 0) AS mv7_total_net_profit,
   ROW_NUMBER() OVER (ORDER BY (cat_net_profit + store_net_profit + web_net_profit) DESC) AS overall_rank
 FROM combined_sales
 WHERE sold_date IS NOT NULL
),
top_profit_dates AS (
 SELECT
   ss.*,
   CASE 
     WHEN ss.cat_net_profit > ss.store_net_profit AND ss.cat_net_profit > ss.web_net_profit THEN 'Catalog'
     WHEN ss.store_net_profit > ss.cat_net_profit AND ss.store_net_profit > ss.web_net_profit THEN 'Store'
     ELSE 'Web'
   END AS leading_channel,
   (SELECT MAX(ws.ws_net_profit)
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IS NOT DISTINCT FROM ss.date_sk
      AND ws.ws_net_profit IS NOT NULL) AS max_web_profit_on_date
 FROM sales_stats ss
 WHERE ss.mv7_total_net_profit > 0
   AND ss.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_stats)
),
call_center_perf AS (
 SELECT
   cc.cc_call_center_id,
   SUM(CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_net_paid_inc_tax ELSE 0 END) AS total_paid_inc_tax,
   SUM(CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_net_profit ELSE 0 END) AS total_profit,
   COUNT(DISTINCT CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_order_number END) AS total_orders,
   CASE
     WHEN SUM(CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_net_profit END) IS NULL THEN NULL
     ELSE ROUND(
       SUM(CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_net_profit END) /
       NULLIF(SUM(CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_net_paid_inc_tax END),0), 4)
   END AS profit_margin
 FROM call_center cc
 LEFT JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
 GROUP BY cc.cc_call_center_id
 HAVING COUNT(DISTINCT CASE WHEN cs.cs_call_center_sk = cc.cc_call_center_sk THEN cs.cs_order_number END) > 0
),
final_union AS (
 SELECT
   tp.sold_date,
   tp.leading_channel,
   tp.total_net_profit,
   tp.mv7_total_net_profit,
   tp.overall_rank,
   COALESCE(ccp.cc_call_center_id, 'UNKNOWN') AS call_center_id,
   COALESCE(ccp.profit_margin, 0) AS profit_margin,
   CONCAT('Date_', CAST(tp.sold_date AS VARCHAR), '_', tp.leading_channel) AS composite_key,
   CASE 
     WHEN tp.max_web_profit_on_date IS NULL THEN 'NO_WEB'
     WHEN tp.max_web_profit_on_date = 0 THEN 'ZERO_WEB'
     ELSE 'HAS_WEB'
   END AS web_status
 FROM top_profit_dates tp
 LEFT JOIN call_center_perf ccp ON ccp.profit_margin > 0.1
 WHERE tp.overall_rank <= 10
)
SELECT * FROM final_union
UNION ALL
SELECT
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   'TOTAL',
   SUM(profit_margin) OVER () AS profit_margin,
   'AGG_TOTAL' AS composite_key,
   CASE WHEN SUM(profit_margin) OVER () IS NULL THEN 'NO_DATA' ELSE 'HAS_DATA' END AS web_status
FROM final_union
INTERSECT
SELECT * FROM final_union WHERE call_center_id = 'UNKNOWN'
EXCEPT
SELECT * FROM final_union WHERE call_center_id = 'TOTAL'
