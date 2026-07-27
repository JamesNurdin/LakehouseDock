WITH
  cs_data AS (
    SELECT
      w.w_warehouse_id,
      sm.sm_ship_mode_id,
      td.t_hour,
      SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
      COUNT(*) AS order_cnt,
      CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ship_mode_sk IN (2, 10, 11)
      AND w.w_warehouse_id = 'AAAAAAAACBAAAAAA'
      AND cs.cs_net_paid_inc_ship_tax > 2000.00
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id, td.t_hour
  ),
  ws_data AS (
    SELECT
      w.w_warehouse_id,
      sm.sm_ship_mode_id,
      td.t_hour,
      SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
      COUNT(*) AS order_cnt,
      CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE we.web_market_manager = 'James Brewer'
      AND we.web_close_date_sk = 2441469
      AND ws.ws_quantity > 5
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_id, sm.sm_ship_mode_id, td.t_hour
  ),
  combined AS (
    SELECT * FROM cs_data
    UNION ALL
    SELECT * FROM ws_data
  )
SELECT
  c.w_warehouse_id,
  c.sm_ship_mode_id,
  SUM(c.total_net_paid) AS sum_net_paid,
  SUM(c.order_cnt) AS sum_orders,
  COUNT(*) AS source_rows,
  RANK() OVER (ORDER BY SUM(c.total_net_paid) DESC) AS revenue_rank,
  CASE WHEN SUM(c.total_net_paid) > 500000 THEN 'TOP' ELSE 'OTHER' END AS tier,
  (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_catalog_profit
FROM combined c
WHERE c.profit_category = 'HIGH'
GROUP BY c.w_warehouse_id, c.sm_ship_mode_id
ORDER BY sum_net_paid DESC
LIMIT 100
