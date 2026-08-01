WITH
  -- Union of bill‑customer and ship‑customer rows to avoid double‑counting the same order
  union_sales AS (
    SELECT
      ws_bill_customer_sk       AS cust_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_web_site_sk,
      ws_ship_mode_sk,
      ws_quantity,
      ws_net_paid
    FROM tpcds.web_sales
    WHERE ws_quantity > 5
    UNION DISTINCT
    SELECT
      ws_ship_customer_sk      AS cust_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_web_site_sk,
      ws_ship_mode_sk,
      ws_quantity,
      ws_net_paid
    FROM tpcds.web_sales
    WHERE ws_quantity > 5
  ),
  -- Full outer join between call_center and catalog_returns (keeps unmatched rows on both sides)
  full_cc_cr AS (
    SELECT
      cr.*,                     -- all catalog_returns columns (may be null)
      cc.cc_name,
      cc.cc_state
    FROM tpcds.call_center cc
    FULL OUTER JOIN tpcds.catalog_returns cr
      ON cc.cc_call_center_sk = cr.cr_call_center_sk
  ),
  -- Apply the star joins from the fact table (web_sales) to all dimension tables
  filtered AS (
    SELECT
      us.cust_sk,
      us.ws_sold_date_sk,
      us.ws_sold_time_sk,
      us.ws_web_site_sk,
      us.ws_ship_mode_sk,
      us.ws_quantity,
      us.ws_net_paid,
      c.c_birth_country,
      c.c_customer_sk,
      ca.ca_state,
      hd.hd_income_band_sk,
      t.t_am_pm,
      t.t_sub_shift,
      ws.web_state,
      sm.sm_type
    FROM union_sales us
    JOIN tpcds.customer c
      ON us.cust_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.time_dim t
      ON us.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.web_site ws
      ON us.ws_web_site_sk = ws.web_site_sk
    JOIN tpcds.ship_mode sm
      ON us.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN full_cc_cr fcr
      ON us.ws_ship_mode_sk = fcr.cr_ship_mode_sk
    WHERE t.t_am_pm = 'PM'
      AND t.t_sub_shift = 'afternoon'
      AND c.c_birth_country = 'JAPAN'
      AND ws.web_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
              AND cr2.cr_return_amount > 1000
          )
  )
SELECT
  f.c_birth_country,
  f.web_state,
  f.sm_type,
  SUM(f.ws_net_paid)                     AS total_net_paid,
  AVG(f.ws_quantity)                     AS avg_quantity,
  COUNT(*)                               AS transaction_cnt,
  MIN(f.ws_quantity)                     AS min_quantity,
  MAX(f.ws_quantity)                     AS max_quantity,
  ROW_NUMBER() OVER (ORDER BY SUM(f.ws_net_paid) DESC)               AS rn_global,
  RANK()       OVER (PARTITION BY f.web_state ORDER BY SUM(f.ws_net_paid) DESC) AS rn_state
FROM filtered f
GROUP BY
  f.c_birth_country,
  f.web_state,
  f.sm_type
ORDER BY total_net_paid DESC
LIMIT 100
