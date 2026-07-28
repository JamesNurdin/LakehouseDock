SELECT
  td.t_hour AS hour,
  ca.ca_state AS state,
  ws.ws_net_paid AS net_paid,
  ib.ib_lower_bound,
  ib.ib_upper_bound
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ca.ca_county = 'Washington County'

UNION ALL

SELECT
  td.t_hour AS hour,
  ca.ca_state AS state,
  ws.ws_net_paid AS net_paid,
  ib.ib_lower_bound,
  ib.ib_upper_bound
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca
  ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN tpcds.time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.household_demographics hd
  ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ca.ca_county = 'Maricopa County'

LIMIT 100
