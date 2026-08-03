WITH catalog_agg AS (
   SELECT
       cr.cr_refunded_customer_sk AS cust_sk,
       SUM(cr.cr_return_amount) AS total_return,
       CONCAT('Cust_', CAST(cr.cr_refunded_customer_sk AS varchar)) AS cust_label,
       REGEXP_EXTRACT(MAX(i.i_item_desc), '([A-Za-z]+)', 1) AS first_word
   FROM
       catalog_returns cr
       JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
       JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE
       i.i_item_desc LIKE '%steel%'
       AND REGEXP_LIKE(i.i_item_desc, '[0-9]{3,}')
   GROUP BY
       cr.cr_refunded_customer_sk
   HAVING
       SUM(cr.cr_return_amount) > 0
       AND cr.cr_refunded_customer_sk NOT IN (
           SELECT
               wr.wr_refunded_customer_sk
           FROM
               web_returns wr
               JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
           WHERE
               r.r_reason_desc LIKE '%damaged%'
       )
),
store_customers AS (
   SELECT DISTINCT sr.sr_customer_sk AS cust_sk
   FROM store_returns sr
   WHERE sr.sr_return_tax > 5
)
SELECT
   cust_sk,
   total_return,
   cust_label,
   first_word
FROM
   catalog_agg
EXCEPT
SELECT
   cust_sk,
   total_return,
   cust_label,
   first_word
FROM
   catalog_agg
WHERE
   cust_sk IN (SELECT cust_sk FROM store_customers)
ORDER BY
   total_return DESC
LIMIT 100
