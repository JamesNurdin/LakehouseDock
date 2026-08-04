WITH
  cr_data AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_returned_time_sk,
      cp.cp_department,
      w.w_warehouse_name,
      r.r_reason_desc AS cr_reason_desc,
      t.t_hour AS cr_hour
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  ),
  sr_data AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_return_time_sk,
      s.s_store_name,
      r.r_reason_desc AS sr_reason_desc,
      t.t_hour AS sr_hour,
      cd.cd_gender AS sr_gender
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  ),
  ws_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_profit,
      ws.ws_sold_time_sk,
      ws.ws_warehouse_sk,
      ws.ws_web_site_sk,
      t.t_hour AS ws_hour,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  ),
  intersect_orders AS (
    SELECT cr_order_number FROM cr_data
    INTERSECT
    SELECT ws_order_number FROM ws_data
  )
SELECT
  COALESCE(sr_data.sr_reason_desc, 'No Store Return Reason') AS reason_desc,
  COALESCE(sr_data.sr_hour, ws_data.ws_hour) AS hour_of_day,
  COUNT(DISTINCT intersect_orders.cr_order_number) AS common_order_count,
  SUM(COALESCE(sr_data.sr_return_amt, 0)) AS total_store_return_amount,
  SUM(COALESCE(ws_data.ws_net_profit, 0)) AS total_web_net_profit,
  AVG(COALESCE(ws_data.ws_net_profit, 0) - COALESCE(sr_data.sr_return_amt, 0)) AS avg_profit_vs_return
FROM sr_data
FULL OUTER JOIN ws_data
  ON sr_data.sr_hour = ws_data.ws_hour
LEFT JOIN intersect_orders
  ON intersect_orders.cr_order_number = COALESCE(sr_data.sr_ticket_number, ws_data.ws_order_number)
WHERE ws_data.ws_net_profit > (
        SELECT MAX(cr_return_amount) FROM catalog_returns
      )
GROUP BY
  COALESCE(sr_data.sr_reason_desc, 'No Store Return Reason'),
  COALESCE(sr_data.sr_hour, ws_data.ws_hour)
ORDER BY total_web_net_profit DESC
LIMIT 100
