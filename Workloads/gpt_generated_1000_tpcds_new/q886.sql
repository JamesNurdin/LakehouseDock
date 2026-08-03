WITH
  web_cust AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_ship > 5000
  ),
  store_cust AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_refunded_cash > 500
  ),
  both_cust AS (
    SELECT c_customer_sk FROM web_cust
    INTERSECT
    SELECT c_customer_sk FROM store_cust
  ),
  store_only_cust AS (
    SELECT c_customer_sk FROM store_cust
    EXCEPT
    SELECT c_customer_sk FROM web_cust
  ),
  sales_agg AS (
    SELECT c.c_customer_sk,
           SUM(ws.ws_net_paid_inc_ship) AS total_sales
    FROM customer c
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_net_paid_inc_ship > 1000
    GROUP BY c.c_customer_sk
  ),
  returns_agg AS (
    SELECT c.c_customer_sk,
           SUM(sr.sr_refunded_cash) AS total_refunds
    FROM customer c
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_refunded_cash > 100
    GROUP BY c.c_customer_sk
  ),
  full_stats AS (
    SELECT COALESCE(s.c_customer_sk, r.c_customer_sk) AS c_customer_sk,
           s.total_sales,
           r.total_refunds
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.c_customer_sk = r.c_customer_sk
  )
SELECT
  c_customer_sk,
  total_sales,
  total_refunds,
  'both' AS customer_type
FROM full_stats
WHERE total_sales IS NOT NULL AND total_refunds IS NOT NULL

UNION

SELECT
  c_customer_sk,
  total_sales,
  total_refunds,
  CASE
    WHEN total_sales IS NOT NULL AND total_refunds IS NULL THEN 'sales_only'
    WHEN total_sales IS NULL AND total_refunds IS NOT NULL THEN 'returns_only'
    ELSE 'unknown'
  END AS customer_type
FROM full_stats
WHERE total_sales IS NOT NULL OR total_refunds IS NOT NULL
