WITH
  sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
  ),
  refunded_info AS (
    SELECT
      wr.wr_refunded_addr_sk AS addr_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_refunded_cash,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      ca.ca_city,
      ca.ca_state,
      ca.ca_street_name,
      ca.ca_street_type
    FROM sampled_returns wr
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_street_name, 'Washington')
      AND ca.ca_street_type LIKE '%Way%'
  ),
  returning_info AS (
    SELECT
      wr.wr_returning_addr_sk AS addr_sk,
      wr.wr_returning_customer_sk,
      wr.wr_refunded_cash,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      ca.ca_city,
      ca.ca_state,
      ca.ca_street_name,
      ca.ca_street_type
    FROM sampled_returns wr
    JOIN household_demographics hd
      ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE lower(ca.ca_street_name) LIKE '%park%'
      AND regexp_extract(ca.ca_street_number, '[0-9]+') BETWEEN '400' AND '600'
  ),
  intersect_addrs AS (
    SELECT addr_sk FROM refunded_info
    INTERSECT
    SELECT addr_sk FROM returning_info
  )
SELECT
  i.addr_sk,
  ca.ca_city,
  ca.ca_state,
  CONCAT(ca.ca_city, ', ', ca.ca_state) AS location,
  SUBSTR(ca.ca_street_name, 1, 5) AS street_prefix,
  SUM(wr.wr_refunded_cash) AS total_refunded_cash,
  COUNT(*) AS return_cnt,
  MAX(hd.hd_income_band_sk) AS max_income_band,
  MIN(hd.hd_income_band_sk) AS min_income_band
FROM intersect_addrs i
JOIN sampled_returns wr
  ON (wr.wr_refunded_addr_sk = i.addr_sk OR wr.wr_returning_addr_sk = i.addr_sk)
JOIN customer_address ca
  ON ca.ca_address_sk = i.addr_sk
JOIN household_demographics hd
  ON (wr.wr_refunded_hdemo_sk = hd.hd_demo_sk OR wr.wr_returning_hdemo_sk = hd.hd_demo_sk)
WHERE regexp_like(ca.ca_street_name, '^W.*')
GROUP BY
  i.addr_sk,
  ca.ca_city,
  ca.ca_state,
  CONCAT(ca.ca_city, ', ', ca.ca_state),
  SUBSTR(ca.ca_street_name, 1, 5)
ORDER BY total_refunded_cash DESC
OFFSET 0 LIMIT 100
