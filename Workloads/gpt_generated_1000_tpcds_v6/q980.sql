WITH agg AS (
  SELECT
    s.s_state,
    s.s_store_name,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN sr.sr_return_quantity > 20 THEN 1 ELSE 0 END) AS large_return_cnt,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(sr.sr_return_tax) AS max_return_tax
  FROM store_returns sr
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN web_sales ws
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE ca.ca_state = 'CA'
    AND ca.ca_county = 'Washington County'
    AND s.s_state = 'CA'
    AND s.s_gmt_offset = -8.00
    AND sr.sr_return_quantity > 10
    AND sr.sr_returned_date_sk BETWEEN 2451500 AND 2452000
    AND ws.ws_coupon_amt > 500
    AND ws.ws_list_price BETWEEN 10 AND 100
    AND ws.ws_ext_ship_cost < 1500
  GROUP BY s.s_state, s.s_store_name, ca.ca_city
)
SELECT
  s_state,
  s_store_name,
  ca_city,
  orders_cnt,
  total_net_paid,
  avg_discount,
  large_return_cnt,
  min_return_amt,
  max_return_tax,
  CASE WHEN large_return_cnt > 5 THEN 'High' ELSE 'Low' END AS return_volume_category,
  SUM(total_net_paid) OVER (PARTITION BY s_state ORDER BY total_net_paid DESC ROWS UNBOUNDED PRECEDING) AS cumulative_state_sales
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
