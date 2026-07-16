WITH store_agg AS (
 SELECT
   d.d_quarter_name AS quarter,
   ca.ca_state AS state,
   ib.ib_lower_bound AS income_lower,
   ib.ib_upper_bound AS income_upper,
   SUM(ss.ss_net_profit) AS store_net_profit,
   SUM(ss.ss_quantity) AS store_quantity,
   AVG(ss.ss_ext_discount_amt) AS store_avg_discount
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
 JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
 JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
 WHERE d.d_year = 2001
 GROUP BY d.d_quarter_name, ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
),
web_agg AS (
 SELECT
   d.d_quarter_name AS quarter,
   ca.ca_state AS state,
   ib.ib_lower_bound AS income_lower,
   ib.ib_upper_bound AS income_upper,
   SUM(ws.ws_net_profit) AS web_net_profit,
   SUM(ws.ws_quantity) AS web_quantity,
   AVG(ws.ws_ext_discount_amt) AS web_avg_discount
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
 JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
 JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
 WHERE d.d_year = 2001
 GROUP BY d.d_quarter_name, ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
  COALESCE(s.quarter, w.quarter) AS quarter,
  COALESCE(s.state, w.state) AS state,
  COALESCE(s.income_lower, w.income_lower) AS income_lower,
  COALESCE(s.income_upper, w.income_upper) AS income_upper,
  s.store_net_profit,
  w.web_net_profit,
  (s.store_net_profit + w.web_net_profit) AS total_net_profit,
  (s.store_quantity + w.web_quantity) AS total_quantity,
  CASE WHEN s.store_quantity > 0 THEN s.store_avg_discount ELSE NULL END AS store_avg_discount,
  CASE WHEN w.web_quantity > 0 THEN w.web_avg_discount ELSE NULL END AS web_avg_discount,
  CASE WHEN s.store_net_profit > 0 THEN w.web_net_profit / s.store_net_profit ELSE NULL END AS web_to_store_profit_ratio
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.quarter = w.quarter
 AND s.state = w.state
 AND s.income_lower = w.income_lower
 AND s.income_upper = w.income_upper
ORDER BY quarter, state, income_lower
