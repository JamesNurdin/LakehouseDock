WITH
  catalog_ret_customers AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS cust_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)access')
  ),
  web_ret_customers AS (
    SELECT DISTINCT wr.wr_returning_customer_sk AS cust_sk
    FROM web_returns wr
  ),
  cust_excluded AS (
    SELECT cust_sk FROM catalog_ret_customers
    EXCEPT
    SELECT cust_sk FROM web_ret_customers
  ),
  customers_with_page AS (
    SELECT DISTINCT wp.wp_customer_sk AS cust_sk
    FROM web_page wp
    WHERE wp.wp_url LIKE 'http%://%example.com%'
  ),
  target_customers AS (
    SELECT cust_sk FROM cust_excluded
    INTERSECT
    SELECT cust_sk FROM customers_with_page
  ),
  store_time AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_customer_sk,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      r.r_reason_desc,
      t.t_hour,
      regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_word
    FROM store_returns sr
    RIGHT OUTER JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_customer_sk IS NOT NULL
      AND sr.sr_customer_sk IN (SELECT cust_sk FROM target_customers)
      AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_returning_customer_sk = sr.sr_customer_sk
          AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
      )
      AND r.r_reason_desc LIKE '%refund%'
      AND regexp_like(r.r_reason_desc, '^.*[Rr]efund.*$')
  )
SELECT
  t_hour,
  reason_word,
  COUNT(DISTINCT sr_ticket_number) AS return_transactions,
  SUM(sr_return_amt) AS total_return_amount,
  SUM(sr_return_quantity) AS total_quantity,
  CONCAT('Hour ', CAST(t_hour AS VARCHAR)) AS hour_label
FROM store_time
GROUP BY t_hour, reason_word
ORDER BY total_return_amount DESC
LIMIT 100
