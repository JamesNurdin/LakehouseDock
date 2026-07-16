WITH
 daily_catalog_sales AS (
   SELECT
     cs_item_sk,
     cs_sold_date_sk,
     SUM(cs_net_paid) AS catalog_net_paid,
     SUM(cs_net_profit) AS catalog_net_profit,
     COUNT(*) AS catalog_sales_cnt
   FROM catalog_sales
   WHERE cs_sold_date_sk IS NOT NULL
   GROUP BY cs_item_sk, cs_sold_date_sk
 ),
 daily_store_sales AS (
   SELECT
     ss_item_sk,
     ss_sold_date_sk,
     SUM(ss_net_paid) AS store_net_paid,
     SUM(ss_net_profit) AS store_net_profit,
     COUNT(*) AS store_sales_cnt
   FROM store_sales
   WHERE ss_sold_date_sk IS NOT NULL
   GROUP BY ss_item_sk, ss_sold_date_sk
 ),
 daily_web_sales AS (
   SELECT
     ws_item_sk,
     ws_sold_date_sk,
     SUM(ws_net_paid) AS web_net_paid,
     SUM(ws_net_profit) AS web_net_profit,
     COUNT(*) AS web_sales_cnt
   FROM web_sales
   WHERE ws_sold_date_sk IS NOT NULL
   GROUP BY ws_item_sk, ws_sold_date_sk
 ),
 combined_daily_sales AS (
   SELECT
     COALESCE(dcs.cs_item_sk, dss.ss_item_sk, dws.ws_item_sk) AS item_sk,
     COALESCE(dcs.cs_sold_date_sk, dss.ss_sold_date_sk, dws.ws_sold_date_sk) AS date_sk,
     COALESCE(dcs.catalog_net_paid, 0) AS catalog_net_paid,
     COALESCE(dcs.catalog_net_profit, 0) AS catalog_net_profit,
     COALESCE(dcs.catalog_sales_cnt, 0) AS catalog_sales_cnt,
     COALESCE(dss.store_net_paid, 0) AS store_net_paid,
     COALESCE(dss.store_net_profit, 0) AS store_net_profit,
     COALESCE(dss.store_sales_cnt, 0) AS store_sales_cnt,
     COALESCE(dws.web_net_paid, 0) AS web_net_paid,
     COALESCE(dws.web_net_profit, 0) AS web_net_profit,
     COALESCE(dws.web_sales_cnt, 0) AS web_sales_cnt
   FROM daily_catalog_sales dcs
   FULL OUTER JOIN daily_store_sales dss
     ON dcs.cs_item_sk = dss.ss_item_sk
    AND dcs.cs_sold_date_sk = dss.ss_sold_date_sk
   FULL OUTER JOIN daily_web_sales dws
     ON COALESCE(dcs.cs_item_sk, dss.ss_item_sk) = dws.ws_item_sk
    AND COALESCE(dcs.cs_sold_date_sk, dss.ss_sold_date_sk) = dws.ws_sold_date_sk
 ),
 item_totals AS (
   SELECT
     c.item_sk,
     i.i_product_name,
     i.i_brand,
     i.i_category,
     SUM(c.catalog_net_paid + c.store_net_paid + c.web_net_paid) AS total_net_paid,
     SUM(c.catalog_net_profit + c.store_net_profit + c.web_net_profit) AS total_net_profit,
     SUM(c.catalog_sales_cnt + c.store_sales_cnt + c.web_sales_cnt) AS total_sales_cnt,
     ROW_NUMBER() OVER (ORDER BY SUM(c.catalog_net_profit + c.store_net_profit + c.web_net_profit) DESC) AS profit_rank
   FROM combined_daily_sales c
   JOIN item i ON i.i_item_sk = c.item_sk
   GROUP BY c.item_sk, i.i_product_name, i.i_brand, i.i_category
 ),
 top_items AS (
   SELECT *
   FROM item_totals
   WHERE profit_rank <= 10
 ),
 call_center_perf AS (
   SELECT
     cc.cc_call_center_sk,
     cc.cc_name,
     COALESCE(cc.cc_closed_date_sk, 0) AS closed_date_flag,
     SUM(COALESCE(cs.cs_net_profit,0)) AS total_call_center_profit,
     COUNT(DISTINCT cs.cs_order_number) AS orders_handled,
     ROW_NUMBER() OVER (PARTITION BY cc.cc_division ORDER BY SUM(COALESCE(cs.cs_net_profit,0)) DESC) AS division_profit_rank
   FROM call_center cc
   LEFT JOIN catalog_sales cs
     ON cc.cc_call_center_sk = cs.cs_call_center_sk
   GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_closed_date_sk, cc.cc_division
 ),
 store_recent_sales AS (
   SELECT
     s.s_store_sk,
     s.s_store_name,
     (SELECT MAX(ss_sold_date_sk) FROM store_sales WHERE store_sales.ss_store_sk = s.s_store_sk) AS last_sale_date_sk,
     COALESCE(SUM(ss_net_paid),0) AS total_store_net_paid,
     COUNT(DISTINCT ss_ticket_number) AS total_tickets
   FROM store s
   LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
   GROUP BY s.s_store_sk, s.s_store_name
 ),
 combined_metrics AS (
   SELECT
     ti.item_sk AS entity_id,
     ti.i_product_name AS entity_name,
     'ITEM' AS entity_type,
     ti.total_net_profit AS metric_value,
     ti.total_sales_cnt AS count_metric,
     NULL AS extra_info,
     ti.profit_rank AS rank_metric
   FROM top_items ti
   UNION ALL
   SELECT
     cp.cc_call_center_sk AS entity_id,
     cp.cc_name AS entity_name,
     'CALL_CENTER' AS entity_type,
     cp.total_call_center_profit AS metric_value,
     cp.orders_handled AS count_metric,
     cp.closed_date_flag AS extra_info,
     cp.division_profit_rank AS rank_metric
   FROM call_center_perf cp
   WHERE cp.division_profit_rank <= 5
   UNION ALL
   SELECT
     sr.s_store_sk AS entity_id,
     sr.s_store_name AS entity_name,
     'STORE' AS entity_type,
     sr.total_store_net_paid AS metric_value,
     sr.total_tickets AS count_metric,
     sr.last_sale_date_sk AS extra_info,
     ROW_NUMBER() OVER (ORDER BY sr.total_store_net_paid DESC) AS rank_metric
   FROM store_recent_sales sr
   WHERE sr.last_sale_date_sk IS NOT NULL
 )
SELECT
  cm.entity_type,
  cm.entity_name,
  cm.metric_value,
  cm.count_metric,
  cm.rank_metric,
  CASE
    WHEN cm.entity_type = 'CALL_CENTER' AND cm.extra_info = 0 THEN 'ACTIVE'
    ELSE 'INACTIVE'
  END AS status_flag,
  CONCAT(cm.entity_type, ': ', cm.entity_name) AS display_label,
  CASE
    WHEN cm.entity_type = 'ITEM' THEN (
      SELECT AVG(COALESCE(cs.cs_ext_discount_amt, 0))
      FROM catalog_sales cs
      WHERE cs.cs_item_sk = cm.entity_id
    )
    ELSE NULL
  END AS avg_catalog_discount
FROM combined_metrics cm
ORDER BY cm.rank_metric
LIMIT 50
