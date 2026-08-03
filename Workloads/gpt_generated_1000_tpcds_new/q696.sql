WITH cs_data AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid,
       cs.cs_item_sk,
       cs.cs_call_center_sk,
       i.i_category,
       cc.cc_name,
       cd_ship.cd_gender AS ship_gender,
       cd_bill.cd_gender AS bill_gender,
       hd_ship.hd_income_band_sk AS ship_income_band,
       hd_bill.hd_income_band_sk AS bill_income_band,
       CASE WHEN cs.cs_net_paid > 1000 THEN 'High' ELSE 'Low' END AS payment_category
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
),
ws_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_net_paid,
       ws.ws_item_sk,
       i.i_category,
       cd_ship.cd_gender AS ship_gender,
       cd_bill.cd_gender AS bill_gender,
       hd_ship.hd_income_band_sk AS ship_income_band,
       hd_bill.hd_income_band_sk AS bill_income_band
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
   LEFT JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
),
common_orders AS (
   SELECT cs_order_number AS order_number FROM cs_data
   INTERSECT
   SELECT ws_order_number FROM ws_data
)
SELECT
   i.i_category,
   cc.cc_name,
   CASE
       WHEN SUM(cs.cs_net_paid) > 50000 THEN 'Very High'
       WHEN SUM(cs.cs_net_paid) > 20000 THEN 'High'
       ELSE 'Medium/Low'
   END AS sales_volume_category,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
   COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
   SUM(cs.cs_net_paid) AS total_catalog_net_paid,
   SUM(ws.ws_net_paid) AS total_web_net_paid
FROM catalog_returns cr
RIGHT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN cs_data cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ws_data ws ON ws.ws_item_sk = cs.cs_item_sk
JOIN item i ON i.i_item_sk = cs.cs_item_sk
JOIN common_orders co ON co.order_number = cs.cs_order_number
GROUP BY i.i_category, cc.cc_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100
