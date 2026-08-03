WITH ups_ship_modes AS (
   SELECT sm_ship_mode_sk
   FROM ship_mode
   WHERE sm_carrier = 'UPS'
),
catalog_agg AS (
   SELECT
       ca.ca_state AS state,
       sm.sm_type AS ship_type,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cs.cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ups_ship_modes)
   GROUP BY GROUPING SETS (
       (ca.ca_state, sm.sm_type),
       (ca.ca_state),
       (sm.sm_type),
       ()
   )
),
web_agg AS (
   SELECT
       ca.ca_state AS state,
       sm.sm_type AS ship_type,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       CASE WHEN SUM(ws.ws_ext_sales_price) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ups_ship_modes)
   GROUP BY GROUPING SETS (
       (ca.ca_state, sm.sm_type),
       (ca.ca_state),
       (sm.sm_type),
       ()
   )
)
SELECT state, ship_type, total_sales, sales_category
FROM catalog_agg
EXCEPT
SELECT state, ship_type, total_sales, sales_category
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
