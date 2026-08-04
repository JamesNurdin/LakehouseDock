WITH
  catalog_part AS (
    SELECT
      d.d_year AS year,
      r.r_reason_desc AS reason,
      ca.ca_state AS state,
      cd.cd_gender AS gender,
      hd.hd_buy_potential AS buy_potential,
      ib.ib_upper_bound AS income_upper,
      COUNT(*) AS return_cnt,
      COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_cnt,
      SUM(DISTINCT cr.cr_return_amount) AS distinct_sum
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY d.d_year, r.r_reason_desc, ca.ca_state, cd.cd_gender, hd.hd_buy_potential, ib.ib_upper_bound
  ),
  store_web_part AS (
    SELECT
      d1.d_year AS year,
      r2.r_reason_desc AS reason,
      ca2.ca_state AS state,
      cd2.cd_gender AS gender,
      hd2.hd_buy_potential AS buy_potential,
      ib2.ib_upper_bound AS income_upper,
      COUNT(*) AS return_cnt,
      COUNT(DISTINCT COALESCE(sr.sr_customer_sk, wr.wr_refunded_customer_sk)) AS distinct_cnt,
      SUM(DISTINCT COALESCE(sr.sr_return_amt, wr.wr_return_amt)) AS distinct_sum
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
      ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
      AND sr.sr_return_time_sk = wr.wr_returned_time_sk
    JOIN date_dim d1 ON COALESCE(sr.sr_returned_date_sk, wr.wr_returned_date_sk) = d1.d_date_sk
    JOIN time_dim t1 ON COALESCE(sr.sr_return_time_sk, wr.wr_returned_time_sk) = t1.t_time_sk
    JOIN reason r2 ON COALESCE(sr.sr_reason_sk, wr.wr_reason_sk) = r2.r_reason_sk
    LEFT JOIN customer_address ca2 ON COALESCE(sr.sr_addr_sk, wr.wr_refunded_addr_sk) = ca2.ca_address_sk
    LEFT JOIN customer_demographics cd2 ON COALESCE(sr.sr_cdemo_sk, wr.wr_refunded_cdemo_sk) = cd2.cd_demo_sk
    LEFT JOIN household_demographics hd2 ON COALESCE(sr.sr_hdemo_sk, wr.wr_refunded_hdemo_sk) = hd2.hd_demo_sk
    LEFT JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d1.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk
    GROUP BY d1.d_year, r2.r_reason_desc, ca2.ca_state, cd2.cd_gender, hd2.hd_buy_potential, ib2.ib_upper_bound
  ),
  union_all AS (
    SELECT
      year,
      reason,
      state,
      gender,
      buy_potential,
      income_upper,
      return_cnt,
      distinct_cnt,
      distinct_sum
    FROM catalog_part
    UNION DISTINCT
    SELECT
      year,
      reason,
      state,
      gender,
      buy_potential,
      income_upper,
      return_cnt,
      distinct_cnt,
      distinct_sum
    FROM store_web_part
  )
SELECT
  year,
  reason,
  state,
  gender,
  buy_potential,
  income_upper,
  return_cnt,
  distinct_cnt,
  distinct_sum,
  ROW_NUMBER() OVER (ORDER BY year DESC, return_cnt DESC) AS rn
FROM union_all
ORDER BY year DESC, return_cnt DESC
LIMIT 100
