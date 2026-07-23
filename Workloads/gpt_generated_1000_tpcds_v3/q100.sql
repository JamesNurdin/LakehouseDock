WITH base_data AS (
  SELECT
    d.d_fy_year,
    d.d_week_seq,
    cc.cc_name,
    cc.cc_state,
    we.web_name,
    we.web_country,
    sm.sm_type,
    w.w_warehouse_name,
    hd.hd_vehicle_count,
    p.p_discount_active,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    sr.sr_ticket_number,
    sr.sr_return_amt_inc_tax,
    sr.sr_net_loss,
    wr.wr_order_number,
    wr.wr_return_amt_inc_tax,
    wr.wr_net_loss,
    inv.inv_quantity_on_hand,
    r.r_reason_desc
  FROM
    date_dim d
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk AND wr.wr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
      AND sr.sr_return_time_sk = t.t_time_sk
      AND wr.wr_returned_time_sk = t.t_time_sk
      AND ws.ws_sold_time_sk = t.t_time_sk
  WHERE
    d.d_fy_year = 1902
    AND d.d_week_seq BETWEEN 5 AND 15
    AND hd.hd_vehicle_count >= 1
    AND p.p_discount_active = 'Y'
    AND sr.sr_return_amt_inc_tax > 1000
    AND ws.ws_quantity > 5
    AND inv.inv_quantity_on_hand < 100
    AND we.web_country = 'United States'
    AND cc.cc_state = 'CA'
    AND r.r_reason_desc LIKE '%defect%'
    AND EXISTS (
      SELECT 1
      FROM inventory inv_check
      WHERE inv_check.inv_warehouse_sk = w.w_warehouse_sk
        AND inv_check.inv_date_sk = d.d_date_sk
        AND inv_check.inv_quantity_on_hand > 500
    )
)
SELECT
  d_fy_year,
  cc_name,
  web_name,
  w_warehouse_name,
  sm_type,
  SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(sr_net_loss) - SUM(wr_net_loss) AS total_net_profit,
  SUM(cs_ext_sales_price) + SUM(ws_ext_sales_price) AS total_sales_amount,
  SUM(sr_return_amt_inc_tax) + SUM(wr_return_amt_inc_tax) AS total_return_amount,
  SUM(cs_quantity) + SUM(ws_quantity) AS total_quantity,
  COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws_order_number) AS web_order_cnt,
  MIN(d_week_seq) AS min_week_seq,
  MAX(d_week_seq) AS max_week_seq
FROM base_data
GROUP BY
  d_fy_year,
  cc_name,
  web_name,
  w_warehouse_name,
  sm_type
HAVING
  (SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(sr_net_loss) - SUM(wr_net_loss)) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
