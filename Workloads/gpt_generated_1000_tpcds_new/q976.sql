WITH sales_filtered AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_item_sk AS item_sk,
          i.i_category,
          i.i_item_desc,
          cs.cs_ext_sales_price AS sales_price,
          cs.cs_sold_time_sk
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '\\d{3}')
     AND i.i_category LIKE 'c%'
),

returns_filtered AS (
   SELECT sr.sr_customer_sk AS customer_sk,
          sr.sr_item_sk AS item_sk,
          r.r_reason_desc,
          sr.sr_return_amt,
          sr.sr_return_time_sk
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%defect%'
),

sales_agg AS (
   SELECT sf.customer_sk,
          SUM(sf.sales_price) AS sales_amount,
          COUNT(*) AS sales_cnt
   FROM sales_filtered sf
   GROUP BY sf.customer_sk
),

returns_agg AS (
   SELECT rf.customer_sk,
          SUM(rf.sr_return_amt) AS return_amount,
          COUNT(*) AS return_cnt
   FROM returns_filtered rf
   GROUP BY rf.customer_sk
),

union_agg AS (
   SELECT customer_sk, sales_amount AS amount, sales_cnt AS cnt, 'sale' AS src
   FROM sales_agg
   UNION
   SELECT customer_sk, return_amount, return_cnt, 'return' AS src
   FROM returns_agg
),

full_joined AS (
   SELECT s.customer_sk,
          s.sales_amount,
          s.sales_cnt,
          r.return_amount,
          r.return_cnt
   FROM sales_agg s
   FULL OUTER JOIN returns_agg r ON s.customer_sk = r.customer_sk
),

filtered_full AS (
   SELECT *
   FROM full_joined f
   WHERE EXISTS (
       SELECT 1
       FROM returns_filtered rf
       WHERE rf.customer_sk = f.customer_sk
   )
),

key_diff AS (
   SELECT customer_sk FROM (
       SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
       FROM catalog_sales cs
   )
   EXCEPT
   SELECT DISTINCT sr.sr_customer_sk
   FROM store_returns sr
)
SELECT
   ff.customer_sk,
   ff.sales_amount,
   ff.return_amount,
   CONCAT('CUST_', CAST(ff.customer_sk AS VARCHAR)) AS cust_key,
   regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS extracted_digits,
   CASE
       WHEN ff.sales_amount > 500 THEN 'HIGH'
       ELSE 'LOW'
   END AS sales_category
FROM filtered_full ff
LEFT JOIN sales_filtered sf ON sf.customer_sk = ff.customer_sk
LEFT JOIN item i ON sf.item_sk = i.i_item_sk
WHERE ff.customer_sk IN (SELECT customer_sk FROM key_diff)
ORDER BY ff.sales_amount DESC NULLS LAST
LIMIT 100
