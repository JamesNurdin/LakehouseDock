WITH
  valid_customers AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      CASE WHEN REGEXP_LIKE(c.c_email_address, '^A.*@example\\.com$') THEN 'A_example' ELSE 'Other' END AS email_category
    FROM tpcds.customer c
    WHERE REGEXP_LIKE(c.c_email_address, '@example\\.com$')
      AND c.c_first_name LIKE 'A%'
  ),
  sales_agg AS (
    SELECT
      ss.ss_customer_sk AS c_customer_sk,
      SUM(ss.ss_net_paid_inc_tax) AS total_spent,
      COUNT(*) AS txn_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_customer_sk
  ),
  customer_no_web_ret AS (
    SELECT c.c_customer_sk
    FROM tpcds.customer c
    WHERE NOT EXISTS (
      SELECT 1
      FROM tpcds.web_returns wr
      WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
    )
  ),
  catalog_ret_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM tpcds.catalog_returns cr
  ),
  web_ret_customers AS (
    SELECT DISTINCT wr.wr_refunded_customer_sk AS c_customer_sk
    FROM tpcds.web_returns wr
  ),
  set_a AS (
    SELECT c.c_customer_sk
    FROM catalog_ret_customers c
    EXCEPT
    SELECT w.c_customer_sk FROM web_ret_customers w
  ),
  set_b AS (
    SELECT c.c_customer_sk
    FROM catalog_ret_customers c
    INTERSECT
    SELECT v.c_customer_sk FROM valid_customers v
  ),
  union_sets AS (
    SELECT c.c_customer_sk FROM set_a c
    UNION
    SELECT b.c_customer_sk FROM set_b b
  )
SELECT
  vc.c_customer_sk,
  vc.full_name,
  vc.email_category,
  sa.total_spent,
  sa.txn_cnt,
  ROW_NUMBER() OVER (ORDER BY sa.total_spent DESC) AS rn,
  CASE WHEN sa.total_spent > 1000 THEN 'High' ELSE 'Low' END AS spend_level
FROM valid_customers vc
JOIN sales_agg sa ON vc.c_customer_sk = sa.c_customer_sk
JOIN union_sets us ON vc.c_customer_sk = us.c_customer_sk
WHERE vc.c_customer_sk IN (SELECT c_customer_sk FROM customer_no_web_ret)
ORDER BY rn
LIMIT 100
