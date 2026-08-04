WITH catalog_ret AS (
   SELECT
       cr.cr_refunded_customer_sk AS cust_sk,
       cr.cr_return_amount,
       i.i_item_desc
   FROM catalog_returns cr
   JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cr.cr_return_amount > 150.00
     AND regexp_like(r.r_reason_desc, '(?i)defect')
),
web_ret AS (
   SELECT
       wr.wr_refunded_customer_sk AS cust_sk,
       wr.wr_return_amt,
       i.i_item_desc
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE wr.wr_return_amt > 150.00
     AND regexp_like(r.r_reason_desc, '(?i)defect')
),
agg_returns AS (
   SELECT
       c.c_customer_id AS customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       SUM(coalesce(cr.cr_return_amount, 0) + coalesce(wr.wr_return_amt, 0)) AS total_return_amount,
       l.extracted_word
   FROM (
        SELECT cust_sk, cr_return_amount, i_item_desc FROM catalog_ret
       ) cr
   FULL JOIN (
        SELECT cust_sk, wr_return_amt, i_item_desc FROM web_ret
       ) wr
     ON cr.cust_sk = wr.cust_sk
   JOIN customer c ON c.c_customer_sk = COALESCE(cr.cust_sk, wr.cust_sk)
   CROSS JOIN LATERAL (
       SELECT regexp_extract(COALESCE(cr.i_item_desc, wr.i_item_desc), '(\\w+)', 1) AS extracted_word
   ) l
   GROUP BY
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       l.extracted_word
   HAVING
       SUM(coalesce(cr.cr_return_amount, 0) + coalesce(wr.wr_return_amt, 0)) > 500
),
store_match AS (
   SELECT c.c_customer_id AS customer_id
   FROM customer c
   WHERE EXISTS (
       SELECT 1
       FROM store_sales ss
       JOIN item i ON ss.ss_item_sk = i.i_item_sk
       WHERE ss.ss_customer_sk = c.c_customer_sk
         AND regexp_like(i.i_product_name, '(?i)Premium')
   )
),
email_filtered AS (
   SELECT c.c_customer_id AS customer_id
   FROM customer c
   WHERE regexp_like(c.c_email_address, '@example\\.com$')
)
SELECT
   a.customer_id,
   a.c_first_name,
   a.c_last_name,
   a.total_return_amount,
   a.extracted_word,
   (SELECT avg(cr_return_amount) FROM catalog_returns) AS avg_return_amount
FROM agg_returns a
WHERE a.customer_id IN (
   SELECT customer_id FROM store_match
   INTERSECT
   SELECT customer_id FROM email_filtered
)
  AND (a.c_first_name LIKE 'J%' OR a.c_last_name LIKE '%son')
  AND substring(a.c_email_address FROM 1 FOR 5) = 'admin'
ORDER BY a.total_return_amount DESC
LIMIT 100
