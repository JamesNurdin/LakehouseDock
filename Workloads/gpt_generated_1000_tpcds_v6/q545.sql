WITH cs_agg AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_sold_date_sk,
       cs.cs_warehouse_sk,
       cs.cs_call_center_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_quantity) AS total_quantity,
       COUNT(*) AS order_cnt
   FROM catalog_sales cs
   WHERE cs.cs_list_price > 100.00
     AND cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
     AND cs.cs_quantity > 0
   GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_warehouse_sk, cs.cs_call_center_sk
)
SELECT
   d_sold.d_year,
   i.i_category,
   w.w_state,
   cc.cc_market_manager,
   wp.wp_type,
   s.s_state,
   SUM(cs_agg.total_sales) AS catalog_sales_total,
   SUM(ws.ws_ext_sales_price) AS web_sales_total,
   SUM(cs_agg.total_quantity + ws.ws_quantity) AS total_quantity,
   SUM(cs_agg.order_cnt) AS catalog_order_count,
   MAX(ws.ws_net_profit) AS max_web_profit
FROM cs_agg
JOIN date_dim d_sold ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws ON ws.ws_item_sk = cs_agg.cs_item_sk
   AND ws.ws_sold_date_sk = cs_agg.cs_sold_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_category = 'Sports'
  AND w.w_state = 'CA'
  AND cc.cc_market_manager = 'Mark Camp'
  AND wp.wp_type = 'content'
GROUP BY d_sold.d_year, i.i_category, w.w_state, cc.cc_market_manager, wp.wp_type, s.s_state
ORDER BY catalog_sales_total DESC
LIMIT 100
