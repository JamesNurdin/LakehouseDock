WITH filtered_customers AS (
  SELECT
    c_customer_sk,
    c_email_address,
    c_salutation,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    split(c_email_address, '@') AS email_parts
  FROM tpcds.customer
  WHERE regexp_like(c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND c_salutation LIKE 'Mr.%'
),
expanded_emails AS (
  SELECT
    fc.c_customer_sk,
    fc.c_email_address,
    fc.c_salutation,
    fc.full_name,
    part AS email_part
  FROM filtered_customers fc
  CROSS JOIN UNNEST(fc.email_parts) AS t(part)
)
SELECT
  ee.c_customer_sk,
  ee.full_name,
  ee.c_salutation,
  ee.email_part,
  COUNT(sr.sr_ticket_number) AS returns_count,
  SUM(sr.sr_refunded_cash) AS total_refunded,
  AVG(sr.sr_return_tax) AS avg_return_tax
FROM expanded_emails ee
JOIN tpcds.store_returns sr
  ON sr.sr_customer_sk = ee.c_customer_sk
WHERE sr.sr_refunded_cash > (
        SELECT AVG(sr2.sr_refunded_cash)
        FROM tpcds.store_returns sr2
      )
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr3
        WHERE sr3.sr_customer_sk = ee.c_customer_sk
          AND sr3.sr_return_amt > 100
      )
GROUP BY
  ee.c_customer_sk,
  ee.full_name,
  ee.c_salutation,
  ee.email_part
HAVING SUM(sr.sr_refunded_cash) > 1000
ORDER BY total_refunded DESC
LIMIT 100
