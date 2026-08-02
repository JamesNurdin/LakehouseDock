WITH sampled_returns AS (
  SELECT
    wr_returned_date_sk,
    wr_returned_time_sk,
    wr_item_sk,
    wr_refunded_customer_sk,
    wr_returning_customer_sk,
    wr_return_quantity,
    wr_return_amt,
    wr_refunded_cash,
    wr_order_number,
    CASE
      WHEN wr_return_amt > 200.00 THEN 'High'
      WHEN wr_return_amt BETWEEN 100.00 AND 200.00 THEN 'Medium'
      ELSE 'Low'
    END AS return_amt_category
  FROM web_returns
  TABLESAMPLE BERNOULLI (10)
  WHERE wr_return_quantity > 1
    AND wr_return_amt > 50.00
    AND wr_returned_time_sk BETWEEN 20000 AND 70000
    AND wr_reason_sk IN (1, 2, 3)
    AND wr_refunded_cash < 500.00
)
SELECT
  COALESCE(c.c_salutation, 'No Customer') AS salutation,
  sr.return_amt_category,
  COUNT(DISTINCT sr.wr_order_number) AS distinct_orders,
  SUM(sr.wr_return_amt) AS total_return_amt,
  AVG(sr.wr_refunded_cash) AS avg_refunded_cash,
  MIN(sr.wr_return_quantity) AS min_return_qty,
  MAX(sr.wr_return_quantity) AS max_return_qty,
  (SELECT COUNT(DISTINCT c_all.c_customer_sk) FROM customer c_all) AS total_customers
FROM sampled_returns sr
FULL OUTER JOIN customer c
  ON sr.wr_refunded_customer_sk = c.c_customer_sk
WHERE
  (c.c_salutation = 'Mr.' OR c.c_salutation = 'Ms.')
  AND c.c_birth_day = 9
  AND sr.wr_returned_time_sk > 30000
  AND sr.wr_refunded_cash BETWEEN 100.00 AND 500.00
  AND sr.wr_returned_time_sk IN (
    SELECT DISTINCT wr_returned_time_sk
    FROM web_returns
    WHERE wr_returned_time_sk BETWEEN 30000 AND 60000
  )
  AND EXISTS (
    SELECT 1
    FROM customer c2
    WHERE c2.c_customer_sk = sr.wr_returning_customer_sk
      AND c2.c_salutation = 'Mrs.'
      AND c2.c_birth_month = 7
  )
GROUP BY GROUPING SETS (
  (c.c_salutation, sr.return_amt_category),
  (c.c_salutation),
  ()
)
ORDER BY
  salutation ASC NULLS LAST,
  return_amt_category ASC,
  total_return_amt DESC
LIMIT 100
