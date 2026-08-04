WITH
  /* Filter store sales to customers born in March */
  store_filtered AS (
    SELECT ss_customer_sk,
           ss_net_paid
    FROM   store_sales
    WHERE  ss_customer_sk IN (
             SELECT c_customer_sk
             FROM   customer
             WHERE  c_birth_month = 3
           )
  ),

  /* Aggregate store sales per customer */
  store_agg AS (
    SELECT ss_customer_sk,
           SUM(ss_net_paid) AS store_net_paid
    FROM   store_filtered
    GROUP BY ss_customer_sk
  ),

  /* Aggregate web sales per customer */
  web_agg AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS web_net_paid
    FROM   web_sales
    GROUP BY ws_bill_customer_sk
  ),

  /* Customers that appear in store sales but not in web sales */
  customer_diff AS (
    SELECT ss_customer_sk
    FROM   store_filtered
    EXCEPT
    SELECT ws_bill_customer_sk
    FROM   web_sales
  ),

  /* Full outer join keeps customers that appear in either channel */
  full_join AS (
    SELECT COALESCE(s.ss_customer_sk, w.ws_bill_customer_sk) AS customer_sk,
           s.store_net_paid,
           w.web_net_paid
    FROM   store_agg s
    FULL OUTER JOIN web_agg w
      ON s.ss_customer_sk = w.ws_bill_customer_sk
  )
SELECT
  fj.customer_sk,
  fj.store_net_paid,
  fj.web_net_paid,
  (
    SELECT SUM(sr.sr_return_amt)
    FROM   store_returns sr
    WHERE  sr.sr_customer_sk = fj.customer_sk
  ) AS total_store_returns,
  CASE
    WHEN fj.customer_sk IN (SELECT ss_customer_sk FROM customer_diff) THEN 'OnlyStore'
    ELSE 'BothOrWebOnly'
  END AS customer_category
FROM   full_join fj
WHERE  fj.customer_sk IN (SELECT ss_customer_sk FROM customer_diff)
LIMIT 100
