WITH intersect_cc AS (
   SELECT cc_call_center_sk FROM call_center WHERE cc_market_manager = 'Earl Wolf'
   INTERSECT
   SELECT cc_call_center_sk FROM call_center WHERE cc_gmt_offset > -5
),
base_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_ship_mode_sk,
       cs.cs_warehouse_sk,
       cs.cs_call_center_sk,
       cs.cs_net_paid_inc_tax,
       cs.cs_ext_ship_cost,
       d.d_year,
       d.d_date,
       cc.cc_name,
       cc.cc_market_manager,
       sm.sm_type,
       w.w_state,
       st.s_store_name,
       st.s_state,
       we.web_name,
       we.web_state
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   FULL OUTER JOIN (
       SELECT s.s_store_sk, s.s_store_name, s.s_state, d_s.d_date_sk AS store_date_sk
       FROM store s
       JOIN date_dim d_s ON s.s_closed_date_sk = d_s.d_date_sk
   ) st ON st.store_date_sk = d.d_date_sk
   FULL OUTER JOIN (
       SELECT ws.web_site_sk, ws.web_name, ws.web_state, d_w.d_date_sk AS web_date_sk
       FROM web_site ws
       JOIN date_dim d_w ON ws.web_open_date_sk = d_w.d_date_sk
   ) we ON we.web_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND cc.cc_market_manager = 'Earl Wolf'
     AND sm.sm_type = 'AIR'
     AND w.w_state = 'CA'
)
SELECT
   bs.d_year,
   bs.cc_name,
   bs.sm_type,
   bs.w_state,
   bs.s_store_name,
   bs.web_name,
   SUM(bs.cs_net_paid_inc_tax) AS total_sales,
   COUNT(*) AS order_cnt,
   l.avg_ship_cost,
   (
       SELECT MAX(cs3.cs_net_paid_inc_tax)
       FROM catalog_sales cs3
       WHERE cs3.cs_sold_date_sk = bs.cs_sold_date_sk
   ) AS max_daily_sales,
   RANK() OVER (PARTITION BY bs.d_year ORDER BY SUM(bs.cs_net_paid_inc_tax) DESC) AS sales_rank_year
FROM base_sales bs
CROSS JOIN LATERAL (
   SELECT AVG(cs2.cs_ext_ship_cost) AS avg_ship_cost
   FROM catalog_sales cs2
   WHERE cs2.cs_ship_mode_sk = bs.cs_ship_mode_sk
) l
WHERE bs.cs_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_cc)
GROUP BY
   bs.d_year,
   bs.cc_name,
   bs.sm_type,
   bs.w_state,
   bs.s_store_name,
   bs.web_name,
   l.avg_ship_cost,
   bs.cs_sold_date_sk
ORDER BY total_sales DESC
LIMIT 100
