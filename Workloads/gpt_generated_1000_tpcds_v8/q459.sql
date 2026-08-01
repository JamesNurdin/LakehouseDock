/*
  Goal: Identify high‑value return customers who also visited web pages belonging to a shop domain, enrich the result with string‑derived fields, apply various analytical constructs, and paginate the output.
*/
WITH sampled_returns AS (
  SELECT *
  FROM store_returns TABLESAMPLE BERNOULLI (10)   -- sample 10% of returns
),

customer_returns AS (
  SELECT
    c.c_customer_sk,
    c.c_salutation,
    c.c_email_address,
    c.c_last_name,
    CONCAT(c.c_salutation, ' ', c.c_last_name) AS full_name,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
  FROM sampled_returns sr
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  GROUP BY ROLLUP (c.c_salutation, c.c_customer_sk, c.c_email_address, c.c_last_name)
),

customer_returns_level AS (
  SELECT
    c_customer_sk,
    c_salutation,
    c_email_address,
    full_name,
    total_return_amt,
    total_qty,
    distinct_tickets,
    CASE
      WHEN total_return_amt > 1000 THEN 'HIGH'
      WHEN total_return_amt > 500 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS return_level
  FROM customer_returns
),

web_pages_filtered AS (
  SELECT
    wp.wp_customer_sk,
    wp.wp_web_page_id,
    wp.wp_url,
    regexp_extract(wp.wp_url, '(https?://[^/]+)') AS domain,
    CASE
      WHEN regexp_like(wp.wp_type, '^home') THEN 'HOME'
      ELSE 'OTHER'
    END AS page_category
  FROM web_page wp
  WHERE wp.wp_url LIKE 'http%://%example.com%'
),

high_return_customers AS (
  SELECT DISTINCT c_customer_sk
  FROM customer_returns_level
  WHERE return_level = 'HIGH'
),

shop_domain_customers AS (
  SELECT DISTINCT wp_customer_sk
  FROM web_pages_filtered
  WHERE domain LIKE '%shop%'
),

intersect_customers AS (
  SELECT c_customer_sk FROM high_return_customers
  INTERSECT
  SELECT wp_customer_sk FROM shop_domain_customers
),

final AS (
  SELECT
    cr.c_salutation,
    cr.return_level,
    cr.total_return_amt,
    cr.total_qty,
    cr.distinct_tickets,
    SUBSTRING(cr.full_name, 1, 12) AS name_prefix,
    (
      SELECT COUNT(*)
      FROM web_page wp2
      WHERE wp2.wp_customer_sk = cr.c_customer_sk
    ) AS web_page_cnt
  FROM customer_returns_level cr
  WHERE cr.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = cr.c_customer_sk
        AND sr2.sr_refunded_cash > 200
    )
)
SELECT *
FROM final
ORDER BY return_level DESC, total_return_amt DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
