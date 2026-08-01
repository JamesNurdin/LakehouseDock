WITH
  catalog_sample AS (
    SELECT
      cr.cr_returning_customer_sk,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_ship_mode_sk,
      cr.cr_return_amount,
      cr.cr_net_loss
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    WHERE cr.cr_return_amount > 0
  ),
  customer_info AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_upper_bound
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  ),
  ship_info AS (
    SELECT
      sm.sm_ship_mode_sk,
      sm.sm_type,
      sm.sm_contract
    FROM ship_mode sm
    WHERE regexp_like(sm.sm_contract, '^U.*')
  ),
  filtered_returns AS (
    SELECT
      cs.cr_returning_customer_sk,
      cs.cr_return_amount,
      cs.cr_net_loss,
      si.sm_type,
      si.sm_contract
    FROM catalog_sample cs
    JOIN ship_info si ON cs.cr_ship_mode_sk = si.sm_ship_mode_sk
    JOIN customer_info ci ON cs.cr_returning_customer_sk = ci.c_customer_sk
    WHERE ci.ca_state = 'TX' AND ci.cd_gender = 'M'
  ),
  store_filtered AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_return_amt,
      sr.sr_net_loss,
      (SELECT sm_type FROM ship_mode WHERE sm_ship_mode_sk = 10) AS sm_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
  ),
  union_returns AS (
    SELECT
      fr.sm_type,
      fr.cr_returning_customer_sk AS customer_sk,
      fr.cr_return_amount AS return_amount,
      fr.cr_net_loss AS net_loss
    FROM filtered_returns fr
    UNION
    SELECT
      sf.sm_type,
      sf.sr_customer_sk AS customer_sk,
      sf.sr_return_amt AS return_amount,
      sf.sr_net_loss AS net_loss
    FROM store_filtered sf
  )
SELECT
  ur.sm_type,
  COUNT(DISTINCT ur.customer_sk) AS distinct_customers,
  SUM(ur.return_amount) AS total_return_amount,
  SUM(ur.net_loss) AS total_net_loss,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cr.cr_returning_customer_sk
      FROM catalog_returns cr
      EXCEPT
      SELECT sr.sr_customer_sk
      FROM store_returns sr
    ) exc
  ) AS catalog_not_in_store_cnt,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cr.cr_returning_customer_sk
      FROM catalog_returns cr
      INTERSECT
      SELECT sr.sr_customer_sk
      FROM store_returns sr
    ) inc
  ) AS catalog_and_store_cnt
FROM union_returns ur
GROUP BY ur.sm_type
ORDER BY total_return_amount DESC
