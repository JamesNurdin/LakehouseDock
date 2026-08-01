WITH base AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_return_time_sk,
    sr.sr_addr_sk,
    sr.sr_store_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss,
    t.t_time_sk,
    t.t_time,
    t.t_hour,
    t.t_am_pm,
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_ship_mode_sk,
    ws.ws_warehouse_sk,
    sm.sm_ship_mode_sk,
    sm.sm_type,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    w.w_state
  FROM store_returns sr
  JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  LEFT JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE t.t_am_pm = 'PM'
    AND w.w_state = 'CA'
    AND sr.sr_fee > 10
    AND ws.ws_quantity > 5
)
SELECT
  b.w_warehouse_name,
  b.sm_type,
  b.ca_city,
  b.t_hour,
  SUM(b.sr_net_loss) AS total_return_loss,
  SUM(b.ws_net_profit) AS total_web_profit,
  COUNT(*) AS txn_count,
  AVG(b.ws_ext_sales_price) AS avg_sales_price,
  ROW_NUMBER() OVER (ORDER BY SUM(b.sr_net_loss) DESC) AS rn,
  v.flag,
  l.item_total_sales
FROM base b
CROSS JOIN (VALUES (1), (2)) AS v(flag)
LEFT JOIN LATERAL (
    SELECT SUM(ws2.ws_ext_sales_price) AS item_total_sales
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = b.ws_item_sk
) AS l ON TRUE
GROUP BY
  b.w_warehouse_name,
  b.sm_type,
  b.ca_city,
  b.t_hour,
  v.flag,
  l.item_total_sales
ORDER BY total_return_loss DESC
OFFSET 20 ROWS
LIMIT 100
