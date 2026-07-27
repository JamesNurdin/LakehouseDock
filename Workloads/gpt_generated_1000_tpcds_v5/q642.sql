WITH joined AS (
  SELECT
    w.w_warehouse_sk,
    w.w_warehouse_name,
    cc.cc_call_center_sk,
    cc.cc_name,
    wp.wp_type,
    cs.cs_ext_sales_price AS cs_sales,
    cs.cs_net_profit AS cs_profit,
    ws.ws_ext_sales_price AS ws_sales,
    ws.ws_net_profit AS ws_profit,
    ca_bill_cs.ca_gmt_offset AS bill_gmt_offset,
    ca_ship_cs.ca_gmt_offset AS ship_gmt_offset,
    wp.wp_rec_start_date
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_bill_cs ON cs.cs_bill_addr_sk = ca_bill_cs.ca_address_sk
  JOIN customer_address ca_ship_cs ON cs.cs_ship_addr_sk = ca_ship_cs.ca_address_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN customer_address ca_bill_ws ON ws.ws_bill_addr_sk = ca_bill_ws.ca_address_sk
  JOIN customer_address ca_ship_ws ON ws.ws_ship_addr_sk = ca_ship_ws.ca_address_sk
  WHERE cc.cc_mkt_id IN (1, 3)
    AND cc.cc_mkt_class LIKE '%basic%'
    AND ca_bill_cs.ca_gmt_offset = -6.00
    AND wp.wp_type = 'order'
    AND wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
    AND ws.ws_net_profit > 0
    AND w.w_city = 'Seattle'
)
SELECT
  w_warehouse_name,
  cc_name,
  wp_type,
  SUM(cs_sales) AS total_catalog_sales,
  SUM(ws_sales) AS total_web_sales,
  SUM(cs_sales) + SUM(ws_sales) AS total_combined_sales,
  RANK() OVER (ORDER BY SUM(cs_sales) + SUM(ws_sales) DESC) AS sales_rank,
  (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_ws_profit,
  AVG(ws_profit) - (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_ws_profit_vs_overall
FROM joined
GROUP BY w_warehouse_name, cc_name, wp_type
ORDER BY total_combined_sales DESC
LIMIT 100
