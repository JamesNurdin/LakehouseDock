WITH base AS (
   SELECT DISTINCT
       d.d_date,
       s.s_store_id,
       s.s_store_name,
       cc.cc_name,
       cp.cp_department,
       wp.wp_type AS web_page_type,
       sm.sm_code AS ship_mode_code,
       w.w_warehouse_name,
       ca.ca_city,
       hd.hd_buy_potential,
       ss.ss_ext_sales_price AS store_sales_amount,
       cs.cs_ext_sales_price AS catalog_sales_amount,
       ws.ws_ext_sales_price AS web_sales_amount,
       inv.inv_quantity_on_hand,
       (COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND s.s_state = 'CA'
     AND sm.sm_code = 'AIR'
     AND ca.ca_country = 'United States'
     AND hd.hd_buy_potential = '5000-10000'
),
store_agg AS (
   SELECT
       s_store_id,
       s_store_name,
       AVG(total_sales) AS avg_total_sales,
       SUM(total_sales) AS sum_total_sales,
       COUNT(*) AS cnt_sales
   FROM base
   GROUP BY s_store_id, s_store_name
   HAVING AVG(total_sales) > 10000
)
SELECT
    sa.s_store_id AS store_id,
    sa.s_store_name AS store_name,
    sa.avg_total_sales,
    sa.sum_total_sales,
    ROW_NUMBER() OVER (ORDER BY sa.avg_total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM base) AS overall_avg_sales
FROM store_agg sa
ORDER BY sa.avg_total_sales DESC
LIMIT 100
