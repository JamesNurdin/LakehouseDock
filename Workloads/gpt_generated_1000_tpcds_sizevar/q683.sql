WITH
  store_agg AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      SUM(sr.sr_return_amt) AS total_store_return,
      COUNT(*) AS store_return_cnt,
      SUM(CASE WHEN sr.sr_return_amt > 100 THEN 1 ELSE 0 END) AS high_value_store_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
    GROUP BY sr.sr_returned_date_sk
  ),
  catalog_agg AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      SUM(cr.cr_return_amount) AS total_catalog_return,
      COUNT(*) AS catalog_return_cnt,
      SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_value_catalog_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
    GROUP BY cr.cr_returned_date_sk
  ),
  customer_returns AS (
    SELECT DISTINCT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
    UNION
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM catalog_returns cr
  ),
  active_customers_2022 AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
  ),
  customers_no_2022 AS (
    SELECT c.c_customer_sk, c.c_email_address, c.c_first_name, c.c_last_name
    FROM customer_returns cr
    JOIN customer c ON cr.c_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '.*@example\\.com$')
    EXCEPT
    SELECT ac.c_customer_sk, NULL, NULL, NULL
    FROM active_customers_2022 ac
  ),
  web_site_active AS (
    SELECT
      ws.web_site_sk,
      ws.web_name,
      ws.web_open_date_sk,
      CONCAT(ws.web_street_type, ' ', ws.web_street_name) AS street_full,
      CASE WHEN regexp_like(ws.web_name, 'Shop') THEN 'Shop' ELSE 'Other' END AS name_category
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
  )
SELECT
  COALESCE(s.date_sk, ca.date_sk) AS return_date_sk,
  d.d_date AS return_date,
  s.total_store_return,
  ca.total_catalog_return,
  (COALESCE(s.total_store_return, 0) - COALESCE(ca.total_catalog_return, 0)) AS net_return_diff,
  CASE
    WHEN COALESCE(s.high_value_store_cnt, 0) > COALESCE(ca.high_value_catalog_cnt, 0) THEN 'StoreHigher'
    WHEN COALESCE(s.high_value_store_cnt, 0) < COALESCE(ca.high_value_catalog_cnt, 0) THEN 'CatalogHigher'
    ELSE 'Equal'
  END AS high_value_comparison,
  cn.c_customer_sk,
  cn.c_email_address,
  regexp_extract(cn.c_email_address, '@(.+)$', 1) AS email_domain,
  CONCAT(cn.c_first_name, ' ', cn.c_last_name) AS full_name,
  CASE WHEN regexp_like(cn.c_first_name, '^A') THEN 'StartsWithA' ELSE 'Other' END AS first_name_flag,
  ws.web_name,
  ws.name_category,
  ws.street_full
FROM store_agg s
FULL OUTER JOIN catalog_agg ca ON s.date_sk = ca.date_sk
LEFT JOIN date_dim d ON COALESCE(s.date_sk, ca.date_sk) = d.d_date_sk
CROSS JOIN customers_no_2022 cn
LEFT JOIN web_site_active ws ON COALESCE(s.date_sk, ca.date_sk) = ws.web_open_date_sk
WHERE cn.c_first_name LIKE 'A%'
ORDER BY net_return_diff DESC
LIMIT 100
