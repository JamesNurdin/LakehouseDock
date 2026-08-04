WITH
  store_f AS (
    SELECT
      sr.sr_return_amt,
      sr.sr_return_tax,
      sr.sr_customer_sk,
      sr.sr_hdemo_sk,
      c.c_customer_sk,
      c.c_first_name,
      c.c_birth_day,
      cd.cd_gender,
      hd.hd_income_band_sk,
      r.r_reason_desc,
      ca.ca_city
    FROM tpcds.store_returns AS sr
    JOIN tpcds.customer AS c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics AS cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics AS hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.reason AS r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address AS ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_id = 'AAAAAAAAJAAAAAAA'
      AND c.c_first_name = 'Karl'
      AND ca.ca_city = 'New Hope'
      AND hd.hd_income_band_sk = 16
      AND sr.sr_return_tax > 10
  ),
  web_f AS (
    SELECT
      wr.wr_return_amt,
      wr.wr_return_tax,
      wr.wr_refunded_customer_sk,
      wr.wr_refunded_hdemo_sk,
      c.c_customer_sk,
      c.c_first_name,
      cd.cd_gender,
      hd.hd_income_band_sk,
      r.r_reason_desc,
      ca.ca_city
    FROM tpcds.web_returns AS wr
    JOIN tpcds.customer AS c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics AS cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics AS hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.reason AS r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_address AS ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE r.r_reason_id = 'AAAAAAAAPAAAAAAA'
      AND c.c_first_name = 'Margie'
      AND ca.ca_city = 'Union'
      AND hd.hd_income_band_sk = 10
      AND wr.wr_return_tax > 5
  ),
  dim_set AS (
    SELECT hd_demo_sk
    FROM tpcds.household_demographics
    WHERE hd_income_band_sk = 16
  ),
  computed_set AS (
    SELECT 1 AS bucket UNION ALL SELECT 2 AS bucket
  )
SELECT
  computed_set.bucket,
  COUNT(DISTINCT store_f.c_customer_sk) AS store_customer_cnt,
  SUM(store_f.sr_return_amt) AS total_store_return_amt,
  AVG(store_f.sr_return_tax) AS avg_store_return_tax,
  COUNT(DISTINCT web_f.c_customer_sk) AS web_customer_cnt,
  SUM(web_f.wr_return_amt) AS total_web_return_amt,
  MIN(web_f.wr_return_tax) AS min_web_return_tax
FROM store_f
CROSS JOIN web_f
JOIN dim_set
  ON store_f.sr_hdemo_sk = dim_set.hd_demo_sk
CROSS JOIN computed_set
GROUP BY computed_set.bucket
ORDER BY total_store_return_amt DESC
LIMIT 100
