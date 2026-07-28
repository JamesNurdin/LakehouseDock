WITH
  cs_agg AS (
    SELECT
      sm_c.sm_carrier,
      t_sold.t_hour,
      SUM(cs.cs_net_profit) AS catalog_profit,
      SUM(cs.cs_net_paid) AS catalog_paid,
      SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_net_paid ELSE 0 END) AS catalog_large_paid,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN ship_mode sm_c ON cs.cs_ship_mode_sk = sm_c.sm_ship_mode_sk
    JOIN customer c_bill_cs ON cs.cs_bill_customer_sk = c_bill_cs.c_customer_sk
    JOIN customer c_ship_cs ON cs.cs_ship_customer_sk = c_ship_cs.c_customer_sk
    JOIN customer_address ca_bill_cs ON cs.cs_bill_addr_sk = ca_bill_cs.ca_address_sk
    JOIN customer_address ca_ship_cs ON cs.cs_ship_addr_sk = ca_ship_cs.ca_address_sk
    JOIN warehouse w_c ON cs.cs_warehouse_sk = w_c.w_warehouse_sk
    GROUP BY sm_c.sm_carrier, t_sold.t_hour
  ),
  ws_agg AS (
    SELECT
      sm_w.sm_carrier,
      t_sold_w.t_hour,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(ws.ws_net_paid) AS web_paid,
      SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_net_paid ELSE 0 END) AS web_large_paid,
      COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN time_dim t_sold_w ON ws.ws_sold_time_sk = t_sold_w.t_time_sk
    JOIN ship_mode sm_w ON ws.ws_ship_mode_sk = sm_w.sm_ship_mode_sk
    JOIN customer c_bill_ws ON ws.ws_bill_customer_sk = c_bill_ws.c_customer_sk
    JOIN customer c_ship_ws ON ws.ws_ship_customer_sk = c_ship_ws.c_customer_sk
    JOIN customer_address ca_bill_ws ON ws.ws_bill_addr_sk = ca_bill_ws.ca_address_sk
    JOIN customer_address ca_ship_ws ON ws.ws_ship_addr_sk = ca_ship_ws.ca_address_sk
    JOIN warehouse w_w ON ws.ws_warehouse_sk = w_w.w_warehouse_sk
    GROUP BY sm_w.sm_carrier, t_sold_w.t_hour
  )
SELECT
  cs.sm_carrier,
  cs.t_hour,
  CASE
    WHEN SUM(cs.catalog_profit + ws.web_profit) > 20000 THEN 'HIGH'
    ELSE 'LOW'
  END AS profit_level,
  SUM(cs.catalog_profit) AS total_catalog_profit,
  SUM(ws.web_profit) AS total_web_profit,
  SUM(cs.catalog_orders) AS total_catalog_orders,
  SUM(ws.web_orders) AS total_web_orders,
  SUM(cs.catalog_large_paid) AS total_catalog_large_paid,
  SUM(ws.web_large_paid) AS total_web_large_paid
FROM cs_agg cs
JOIN ws_agg ws
  ON cs.sm_carrier = ws.sm_carrier
 AND cs.t_hour = ws.t_hour
GROUP BY cs.sm_carrier, cs.t_hour
HAVING SUM(cs.catalog_profit + ws.web_profit) > 10000
ORDER BY cs.sm_carrier, cs.t_hour DESC
LIMIT 100
