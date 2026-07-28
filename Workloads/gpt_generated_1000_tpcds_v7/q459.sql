/*
Goal: Analyze total and average web sales by website, item category, household buying potential and customer location for a specific product color, container type, vehicle ownership level and market segment.
*/
SELECT
    ws_site.web_name,
    ws_site.web_state,
    ws_site.web_zip,
    ca.ca_state,
    ca.ca_city,
    i.i_category,
    hd.hd_buy_potential,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM tpcds.web_sales ws
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE i.i_color = 'rosy'
  AND i.i_container = 'Unknown'
  AND hd.hd_vehicle_count = 2
  AND ws_site.web_mkt_id = 3
  AND ws_site.web_zip = '41933'
  AND ws.ws_quantity > 1
GROUP BY
    ws_site.web_name,
    ws_site.web_state,
    ws_site.web_zip,
    ca.ca_state,
    ca.ca_city,
    i.i_category,
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
