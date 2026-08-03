WITH billed AS (
   SELECT cs_bill_customer_sk AS cust_sk,
          sum(cs_ext_sales_price) AS total_billed_sales
   FROM catalog_sales
   WHERE cs_ext_sales_price > 1000
   GROUP BY cs_bill_customer_sk
),
shipped AS (
   SELECT cs_ship_customer_sk AS cust_sk,
          sum(cs_ext_sales_price) AS total_shipped_sales
   FROM catalog_sales
   WHERE cs_ext_sales_price > 1000
   GROUP BY cs_ship_customer_sk
),
cust_list AS (
   SELECT cust_sk FROM billed
   EXCEPT
   SELECT cust_sk FROM shipped
)
SELECT
   c.c_customer_sk,
   concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
   regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
   CASE
      WHEN regexp_like(c.c_email_address, '^.*@gmail\\.com$') THEN 'Gmail'
      ELSE 'Other'
   END AS email_provider,
   b.total_billed_sales,
   (
      SELECT sum(cs_net_profit)
      FROM catalog_sales cs2
      WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
   ) AS total_net_profit,
   (
      SELECT count(*)
      FROM catalog_sales cs3
      WHERE cs3.cs_bill_customer_sk = c.c_customer_sk
        AND cs3.cs_net_paid > 5000
   ) AS high_value_sales_cnt
FROM cust_list cl
JOIN customer c ON cl.cust_sk = c.c_customer_sk
LEFT JOIN billed b ON b.cust_sk = c.c_customer_sk
WHERE c.c_birth_country LIKE 'U%'
  AND EXISTS (
      SELECT 1
      FROM catalog_sales cs4
      WHERE cs4.cs_bill_customer_sk = c.c_customer_sk
        AND cs4.cs_ext_discount_amt > 0
   )
ORDER BY b.total_billed_sales DESC
LIMIT 100
