WITH
  sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      d.d_year,
      SUM(ws.ws_net_paid) AS total_net_paid,
      AVG(ws.ws_net_paid) AS avg_net_paid,
      COUNT(*) AS order_cnt,
      MAX(ws.ws_net_paid) AS max_net_paid,
      MIN(ws.ws_net_paid) AS min_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND ca.ca_state = 'CA'
    GROUP BY ws.ws_bill_customer_sk, d.d_year
  ),
  store_ret_agg AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      d.d_year,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND sr.sr_return_quantity > 0
      AND sr.sr_fee > 10
    GROUP BY sr.sr_customer_sk, d.d_year
  ),
  catalog_ret_keys AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_month_seq = 1200
      AND cp.cp_type = 'A'
      AND sm.sm_type = 'AIR'
  ),
  common_customers AS (
    SELECT customer_sk FROM sales_agg
    INTERSECT
    SELECT customer_sk FROM store_ret_agg
  )
SELECT
  t.customer_sk,
  t.d_year,
  t.total_net_paid,
  t.total_return_amt,
  t.net_contrib,
  t.overall_avg_profit,
  t.ib_income_band_sk,
  t.const
FROM (
  SELECT
    cc.customer_sk,
    sa.d_year,
    sa.total_net_paid,
    sr.total_return_amt,
    (sa.total_net_paid - sr.total_return_amt) AS net_contrib,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY (sa.total_net_paid - sr.total_return_amt) DESC) AS rnk,
    (SELECT AVG(ws_net_profit) FROM web_sales) AS overall_avg_profit,
    ib.ib_income_band_sk,
    consts.const
  FROM common_customers cc
  JOIN sales_agg sa ON cc.customer_sk = sa.customer_sk
  JOIN store_ret_agg sr ON cc.customer_sk = sr.customer_sk AND sa.d_year = sr.d_year
  JOIN customer c ON cc.customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  CROSS JOIN (VALUES (1), (2)) AS consts(const)
  CROSS JOIN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 30000) AS iv
  WHERE cc.customer_sk NOT IN (SELECT customer_sk FROM catalog_ret_keys)
    AND ib.ib_lower_bound BETWEEN 20000 AND 80000
    AND hd.hd_dep_count <= 5
    AND EXISTS (
      SELECT 1 FROM web_returns wr
      WHERE wr.wr_returning_customer_sk = cc.customer_sk
        AND wr.wr_return_quantity > 1
    )
) t
WHERE t.rnk <= 5
ORDER BY t.d_year DESC, t.net_contrib DESC
LIMIT 100
