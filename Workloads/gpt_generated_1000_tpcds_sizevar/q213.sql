WITH catalog_customers AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk,
          c.c_first_name,
          c.c_last_name,
          c.c_email_address,
          cd.cd_credit_rating
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE regexp_like(cp.cp_description, '(?i)women')
     AND cd.cd_credit_rating = 'Good'
),
web_customers AS (
   SELECT ws.ws_bill_customer_sk AS customer_sk,
          c.c_first_name,
          c.c_last_name,
          c.c_email_address,
          cd.cd_credit_rating
   FROM web_sales ws
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE wsit.web_name LIKE 'Amazon%'
),
union_customers AS (
   SELECT * FROM catalog_customers
   UNION
   SELECT * FROM web_customers
),
non_return_customers AS (
   SELECT customer_sk FROM union_customers
   EXCEPT
   SELECT cr.cr_refunded_customer_sk FROM catalog_returns cr
),
final_set AS (
   SELECT uc.customer_sk,
          CONCAT(uc.c_first_name, ' ', uc.c_last_name) AS full_name,
          SUBSTR(uc.c_email_address, 1, 5) AS email_prefix,
          uc.cd_credit_rating
   FROM union_customers uc
   JOIN non_return_customers nrc ON uc.customer_sk = nrc.customer_sk
)
SELECT fs.cd_credit_rating,
       COUNT(DISTINCT fs.customer_sk) AS unique_customers,
       COUNT(*) AS total_rows,
       MAX(fs.email_prefix) AS example_prefix
FROM final_set fs
GROUP BY fs.cd_credit_rating
ORDER BY unique_customers DESC
LIMIT 100
