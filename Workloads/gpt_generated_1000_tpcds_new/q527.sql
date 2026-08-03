WITH
  store_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS store_return_cnt,
      ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(sr.sr_return_amt) DESC) AS rn_income_band
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND ib.ib_upper_bound <= 150000
    GROUP BY
      c.c_customer_sk,
      c.c_email_address,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
  ),

  web_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(*) AS web_return_cnt,
      ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_income_band
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND ib.ib_lower_bound >= 30000
    GROUP BY
      c.c_customer_sk,
      c.c_email_address,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
  ),

  union_all AS (
    SELECT
      c_customer_sk,
      c_email_address,
      ib_income_band_sk,
      ib_lower_bound,
      ib_upper_bound,
      total_return_amt,
      store_return_cnt AS return_cnt,
      'store' AS source,
      rn_income_band
    FROM store_agg
    UNION DISTINCT
    SELECT
      c_customer_sk,
      c_email_address,
      ib_income_band_sk,
      ib_lower_bound,
      ib_upper_bound,
      total_return_amt,
      web_return_cnt AS return_cnt,
      'web' AS source,
      rn_income_band
    FROM web_agg
  ),

  full_join AS (
    SELECT
      u.c_customer_sk,
      u.c_email_address,
      u.ib_income_band_sk,
      u.ib_lower_bound,
      u.ib_upper_bound,
      u.total_return_amt,
      u.return_cnt,
      u.source,
      u.rn_income_band,
      CASE WHEN u.total_return_amt IS NULL THEN 0 ELSE u.total_return_amt END AS adjusted_return_amt
    FROM union_all u
    FULL OUTER JOIN income_band ib2
      ON u.ib_income_band_sk = ib2.ib_income_band_sk
    WHERE (u.total_return_amt IS NOT NULL OR ib2.ib_income_band_sk IS NOT NULL)
      AND (u.source = 'store' OR u.source = 'web')
  )
SELECT DISTINCT
  c_customer_sk,
  c_email_address,
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  adjusted_return_amt,
  return_cnt,
  source,
  rn_income_band,
  DENSE_RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY adjusted_return_amt DESC) AS income_band_rank
FROM full_join
ORDER BY ib_income_band_sk, income_band_rank
LIMIT 100
