WITH
  sample_cust AS (
    SELECT *
    FROM customer TABLESAMPLE BERNOULLI (10)
    WHERE c_birth_day = 15
      AND c_birth_month = 4
      AND c_birth_year = 1955
      AND c_preferred_cust_flag = 'Y'
      AND c_login LIKE 'user_%'
  ),
  addr_filtered AS (
    SELECT *
    FROM customer_address
    WHERE ca_street_type = 'Pkwy'
      AND ca_city = 'Washington'
      AND ca_zip = '98109'
  ),
  store_agg AS (
    SELECT
      c.c_customer_sk,
      ca.ca_state,
      SUM(sr.sr_return_amt) AS store_return_sum,
      AVG(sr.sr_return_tax) AS store_return_tax_avg,
      COUNT(*) AS store_return_cnt,
      MIN(sr.sr_return_amt_inc_tax) AS store_return_min_inc,
      MAX(sr.sr_return_amt_inc_tax) AS store_return_max_inc
    FROM store_returns sr
    JOIN sample_cust c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN addr_filtered ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_tax > 10
      AND sr.sr_return_quantity >= 1
      AND sr.sr_fee BETWEEN 10 AND 60
    GROUP BY c.c_customer_sk, ca.ca_state
  ),
  web_agg AS (
    SELECT
      c.c_customer_sk,
      ca.ca_state,
      SUM(wr.wr_return_amt) AS web_return_sum,
      AVG(wr.wr_return_tax) AS web_return_tax_avg,
      COUNT(*) AS web_return_cnt,
      MIN(wr.wr_return_amt_inc_tax) AS web_return_min_inc,
      MAX(wr.wr_return_amt_inc_tax) AS web_return_max_inc
    FROM web_returns wr
    JOIN sample_cust c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN addr_filtered ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_tax > 5
      AND wr.wr_return_quantity >= 1
      AND wr.wr_fee BETWEEN 5 AND 55
    GROUP BY c.c_customer_sk, ca.ca_state
  ),
  intersect_keys AS (
    SELECT c_customer_sk
    FROM store_agg
    INTERSECT
    SELECT c_customer_sk
    FROM web_agg
  ),
  union_agg AS (
    SELECT
      c_customer_sk,
      ca_state,
      store_return_sum AS total_return_sum,
      store_return_tax_avg AS total_return_tax_avg,
      store_return_cnt AS total_return_cnt,
      store_return_min_inc AS total_min_inc,
      store_return_max_inc AS total_max_inc
    FROM store_agg
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM intersect_keys)
    UNION
    SELECT
      c_customer_sk,
      ca_state,
      web_return_sum,
      web_return_tax_avg,
      web_return_cnt,
      web_return_min_inc,
      web_return_max_inc
    FROM web_agg
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM intersect_keys)
  ),
  full_joined AS (
    SELECT
      COALESCE(s.c_customer_sk, w.c_customer_sk) AS customer_sk,
      COALESCE(s.ca_state, w.ca_state) AS state,
      s.store_return_sum,
      w.web_return_sum,
      s.store_return_cnt,
      w.web_return_cnt
    FROM store_agg s
    FULL OUTER JOIN web_agg w
      ON s.c_customer_sk = w.c_customer_sk
     AND s.ca_state = w.ca_state
  ),
  ranked AS (
    SELECT
      customer_sk,
      state,
      store_return_sum,
      web_return_sum,
      store_return_cnt,
      web_return_cnt,
      ROW_NUMBER() OVER (
        PARTITION BY state
        ORDER BY (COALESCE(store_return_sum, 0) + COALESCE(web_return_sum, 0)) DESC
      ) AS rn
    FROM full_joined
  )
SELECT
  customer_sk,
  state,
  store_return_sum,
  web_return_sum,
  store_return_cnt,
  web_return_cnt
FROM ranked
WHERE rn <= 5
ORDER BY state, rn
LIMIT 100
