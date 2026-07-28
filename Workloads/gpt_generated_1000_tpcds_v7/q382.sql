WITH filtered_customers AS (
  SELECT c.c_customer_sk
  FROM customer c
  WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
      AND ws2.ws_sold_date_sk > 2450000
  )
)
SELECT
  cc.cc_name,
  ws_site.web_name,
  s.s_store_name,
  SUM(cs.cs_net_paid) AS total_catalog_net_paid,
  SUM(ws.ws_net_paid) AS total_web_net_paid,
  SUM(sr.sr_net_loss) AS total_store_returns_loss,
  COUNT(DISTINCT c1.c_customer_sk) AS distinct_customers
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c1 ON cs.cs_bill_customer_sk = c1.c_customer_sk
JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
JOIN customer_address ca1 ON cs.cs_bill_addr_sk = ca1.ca_address_sk
JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
JOIN web_sales ws ON c1.c_customer_sk = ws.ws_bill_customer_sk
JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN customer c2 ON ws.ws_ship_customer_sk = c2.c_customer_sk
JOIN household_demographics hd2 ON ws.ws_ship_hdemo_sk = hd2.hd_demo_sk
JOIN customer_address ca2 ON ws.ws_ship_addr_sk = ca2.ca_address_sk
JOIN store_returns sr ON c1.c_customer_sk = sr.sr_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd3 ON sr.sr_hdemo_sk = hd3.hd_demo_sk
JOIN customer_address ca3 ON sr.sr_addr_sk = ca3.ca_address_sk
WHERE c1.c_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
GROUP BY cc.cc_name, ws_site.web_name, s.s_store_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100
