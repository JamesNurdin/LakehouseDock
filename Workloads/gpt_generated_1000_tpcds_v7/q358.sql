WITH filtered_sales AS (
  SELECT
    ws.ws_net_profit,
    ca.ca_state,
    sm.sm_type,
    sm.sm_ship_mode_id,
    concat(ca.ca_state, '-', sm.sm_type) AS state_ship_label
  FROM web_sales ws
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE regexp_like(ca.ca_city, 'York')
    AND sm.sm_ship_mode_id LIKE 'SM_%'
    AND hd.hd_buy_potential = '501-1000'
)
SELECT
  ca_state,
  sm_type,
  state_ship_label,
  regexp_extract(sm_ship_mode_id, 'SM_(.*)', 1) AS ship_mode_suffix,
  sum(ws_net_profit) AS total_net_profit,
  count(*) AS orders
FROM filtered_sales
GROUP BY ca_state, sm_type, state_ship_label, regexp_extract(sm_ship_mode_id, 'SM_(.*)', 1)
ORDER BY total_net_profit DESC
LIMIT 200
