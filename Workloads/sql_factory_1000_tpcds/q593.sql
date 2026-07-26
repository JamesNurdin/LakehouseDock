WITH address_hh_agg AS (
  SELECT
    ws.ws_bill_addr_sk,
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS order_cnt,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    AVG(ws.ws_list_price) AS avg_list_price,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  GROUP BY ws.ws_bill_addr_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, w.w_warehouse_name, hd.hd_buy_potential
)
SELECT
  aha.ca_address_id,
  aha.ca_city,
  aha.ca_state,
  aha.w_warehouse_name,
  aha.hd_buy_potential,
  aha.total_net_paid,
  aha.order_cnt,
  CASE WHEN aha.avg_discount_amt / NULLIF(aha.avg_list_price, 0) > 0.2 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
  DENSE_RANK() OVER (ORDER BY aha.total_net_paid DESC) AS net_paid_rank,
  SUM(aha.total_net_paid) OVER (ORDER BY aha.total_net_paid DESC ROWS UNBOUNDED PRECEDING) AS cumulative_net_paid,
  aha.avg_vehicle_cnt
FROM address_hh_agg aha
ORDER BY aha.total_net_paid DESC
LIMIT 15
