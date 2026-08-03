WITH
  max_return AS (
    SELECT max(cr_return_amount) AS max_amount
    FROM catalog_returns
  ),
  refunded AS (
    SELECT
      cust.c_customer_id,
      d.d_year AS return_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END AS amount_category,
      ROW_NUMBER() OVER (PARTITION BY cust.c_customer_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rank_per_customer
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer cust
      ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND cr.cr_return_amount > (SELECT max_amount FROM max_return) * 0.5
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = cr.cr_returning_customer_sk
          AND cr2.cr_return_amount > 0
      )
    GROUP BY
      cust.c_customer_id,
      d.d_year,
      CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END
  ),
  returning AS (
    SELECT
      cust.c_customer_id,
      d.d_year AS return_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END AS amount_category,
      ROW_NUMBER() OVER (PARTITION BY cust.c_customer_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rank_per_customer
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer cust
      ON cr.cr_returning_customer_sk = cust.c_customer_sk
    WHERE d.d_year = 2002
      AND t.t_shift = 'second'
      AND cr.cr_return_amount > (SELECT max_amount FROM max_return) * 0.5
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = cr.cr_returning_customer_sk
          AND cr2.cr_return_amount > 0
      )
    GROUP BY
      cust.c_customer_id,
      d.d_year,
      CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END
  )
SELECT *
FROM refunded
UNION ALL
SELECT *
FROM returning
ORDER BY return_year DESC, total_return_amount DESC
LIMIT 100
