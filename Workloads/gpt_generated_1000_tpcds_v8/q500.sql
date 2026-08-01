WITH
cs_joined AS (
   SELECT
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       d.d_year,
       cp.cp_department,
       sm.sm_type AS ship_type,
       w.w_warehouse_name,
       c_bill.c_customer_id AS bill_customer_id,
       ca_bill.ca_state AS bill_state,
       c_ship.c_customer_id AS ship_customer_id,
       ca_ship.ca_state AS ship_state,
       cd_bill.cd_gender,
       hd_bill.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
   JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
   JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cs.cs_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 0)
),
ws_joined AS (
   SELECT
       ws.ws_order_number,
       ws.ws_ext_sales_price,
       d.d_year,
       wp.wp_type,
       sm.sm_type AS ship_type,
       w.w_warehouse_name,
       c_bill.c_customer_id AS bill_customer_id,
       ca_bill.ca_state AS bill_state,
       c_ship.c_customer_id AS ship_customer_id,
       ca_ship.ca_state AS ship_state,
       cd_bill.cd_gender,
       hd_bill.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
   JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ws.ws_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 0)
),
ss_joined AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_ext_sales_price,
       d.d_year,
       s.s_store_name,
       c.c_customer_id,
       ca.ca_state,
       cd.cd_gender,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
union_sales AS (
   SELECT cs_order_number AS order_id, cs_ext_sales_price AS sales_amount, 'catalog' AS src FROM cs_joined
   UNION
   SELECT ws_order_number AS order_id, ws_ext_sales_price AS sales_amount, 'web' AS src FROM ws_joined
   UNION
   SELECT ss_ticket_number AS order_id, ss_ext_sales_price AS sales_amount, 'store' AS src FROM ss_joined
),
return_orders AS (
   SELECT cr_order_number AS order_id FROM catalog_returns
   UNION
   SELECT wr_order_number AS order_id FROM web_returns
),
valid_orders AS (
   SELECT order_id FROM union_sales
   EXCEPT
   SELECT order_id FROM return_orders
)
SELECT
   vo.order_id,
   SUM(us.sales_amount) AS total_sales,
   COUNT(DISTINCT us.src) AS channel_count,
   CASE WHEN SUM(us.sales_amount) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
   ROW_NUMBER() OVER (ORDER BY SUM(us.sales_amount) DESC) AS rn
FROM union_sales us
JOIN valid_orders vo ON us.order_id = vo.order_id
GROUP BY vo.order_id
HAVING SUM(us.sales_amount) > 0
ORDER BY total_sales DESC
LIMIT 100
