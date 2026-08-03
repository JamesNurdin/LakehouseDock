WITH
  base AS (
    SELECT
      cc.cc_call_center_id,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      sm.sm_type,
      cr.cr_return_amount,
      cr.cr_fee,
      ca.ca_city,
      hd.hd_dep_count
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 50000
      AND ib.ib_lower_bound < 150000
      AND sm.sm_type = 'AIR'
      AND cc.cc_state = 'CA'
      AND cr.cr_fee > 10
      AND ca.ca_city NOT LIKE 'San%'
      AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_returning_addr_sk = ca.ca_address_sk
          AND cr2.cr_return_amount > 5000
      )
  ),

  agg_per_cc AS (
    SELECT
      cc_call_center_id,
      ib_lower_bound,
      ib_upper_bound,
      sm_type,
      SUM(cr_return_amount) AS sum_return_amount,
      COUNT(*) AS cnt_returns
    FROM base
    GROUP BY cc_call_center_id, ib_lower_bound, ib_upper_bound, sm_type
  ),

  base_ret AS (
    SELECT
      cc.cc_call_center_id,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      sm.sm_type,
      cr.cr_return_amount,
      cr.cr_fee,
      ca2.ca_city,
      hd2.hd_dep_count
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca2
      ON cr.cr_returning_addr_sk = ca2.ca_address_sk
    JOIN household_demographics hd2
      ON cr.cr_returning_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib
      ON hd2.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 50000
      AND ib.ib_lower_bound < 150000
      AND sm.sm_type = 'AIR'
      AND cc.cc_state = 'CA'
      AND cr.cr_fee > 10
      AND ca2.ca_city NOT LIKE 'San%'
      AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr3
        WHERE cr3.cr_refunded_addr_sk = ca2.ca_address_sk
          AND cr3.cr_return_amount > 5000
      )
  ),

  agg_per_cc_ret AS (
    SELECT
      cc_call_center_id,
      ib_lower_bound,
      ib_upper_bound,
      sm_type,
      SUM(cr_return_amount) AS sum_return_amount,
      COUNT(*) AS cnt_returns
    FROM base_ret
    GROUP BY cc_call_center_id, ib_lower_bound, ib_upper_bound, sm_type
  ),

  combined AS (
    SELECT * FROM agg_per_cc
    UNION
    SELECT * FROM agg_per_cc_ret
  )
SELECT
  sm_type,
  AVG(sum_return_amount) AS avg_sum_return,
  SUM(cnt_returns) AS total_returns
FROM combined
GROUP BY sm_type
HAVING AVG(sum_return_amount) > 1000
ORDER BY avg_sum_return DESC
OFFSET 0
LIMIT 100
