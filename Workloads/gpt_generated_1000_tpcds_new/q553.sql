WITH
  refunded_join AS (
    SELECT
      c.c_customer_sk AS c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      CASE WHEN wr.wr_return_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS amt_category,
      (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk) AS total_refunds_by_customer
    FROM customer c
    FULL OUTER JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year >= 1960
  ),
  returning_join AS (
    SELECT
      c.c_customer_sk AS c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      CASE WHEN wr.wr_return_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS amt_category,
      (SELECT COUNT(*) FROM web_returns wr2 WHERE wr2.wr_returning_customer_sk = c.c_customer_sk) AS total_returns_by_customer
    FROM customer c
    FULL OUTER JOIN web_returns wr
      ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year >= 1960
  ),
  intersect_set AS (
    SELECT DISTINCT c_customer_sk FROM refunded_join
    INTERSECT
    SELECT DISTINCT c_customer_sk FROM returning_join
  ),
  final AS (
    SELECT
      r.c_customer_sk,
      r.c_first_name,
      r.c_last_name,
      r.wr_return_amt,
      r.amt_category,
      lt.total_refunds_by_customer,
      (SELECT MAX(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = r.c_customer_sk) AS max_refund_amt
    FROM refunded_join r
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS total_refunds_by_customer
      FROM web_returns wr3
      WHERE wr3.wr_refunded_customer_sk = r.c_customer_sk
    ) lt ON TRUE
    WHERE r.c_customer_sk IN (SELECT c_customer_sk FROM intersect_set)
  )
SELECT DISTINCT
  c_customer_sk,
  c_first_name,
  c_last_name,
  amt_category,
  max_refund_amt
FROM final
ORDER BY max_refund_amt DESC
LIMIT 100
