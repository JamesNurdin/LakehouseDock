WITH
catalog_filtered AS (
   SELECT
     cp.cp_catalog_page_sk,
     cp.cp_catalog_page_id,
     cp.cp_department,
     cp.cp_type,
     cp.cp_description,
     regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
     regexp_like(cp.cp_description, '(?i)discount') AS has_discount
   FROM catalog_page cp
   WHERE cp.cp_type LIKE 'C%'
     AND regexp_like(cp.cp_description, '(?i)discount')
),
catalog_sales_agg AS (
   SELECT
     cs.cs_bill_customer_sk,
     cs.cs_catalog_page_sk,
     SUM(cs.cs_net_paid) AS total_net_paid,
     COUNT(*) AS sales_cnt,
     ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank
   FROM catalog_sales cs
   JOIN catalog_filtered cf
     ON cs.cs_catalog_page_sk = cf.cp_catalog_page_sk
   GROUP BY cs.cs_bill_customer_sk, cs.cs_catalog_page_sk
),
store_agg AS (
   SELECT
     ss.ss_customer_sk,
     SUM(ss.ss_net_paid) AS store_net_paid,
     COUNT(*) AS store_txn_cnt
   FROM store_sales ss
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ss.ss_customer_sk
),
web_agg AS (
   SELECT
     ws.ws_bill_customer_sk,
     SUM(ws.ws_net_paid) AS web_net_paid,
     COUNT(*) AS web_txn_cnt
   FROM web_sales ws
   JOIN date_dim d2
     ON ws.ws_sold_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
   GROUP BY ws.ws_bill_customer_sk
),
full_sales AS (
   SELECT
     COALESCE(s.ss_customer_sk, w.ws_bill_customer_sk) AS customer_sk,
     s.store_net_paid,
     w.web_net_paid
   FROM store_agg s
   FULL OUTER JOIN web_agg w
     ON s.ss_customer_sk = w.ws_bill_customer_sk
),
customer_demo_filter AS (
   SELECT cd.cd_demo_sk
   FROM customer_demographics cd
   WHERE cd.cd_gender = 'M' AND cd.cd_education_status = 'College'
),
customers_with_demo AS (
   SELECT c.c_customer_sk, c.c_first_name, c.c_last_name
   FROM customer c
   WHERE c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demo_filter)
),
store_customers AS (
   SELECT ss.ss_customer_sk AS customer_sk
   FROM store_sales ss
   GROUP BY ss.ss_customer_sk
),
web_customers AS (
   SELECT ws.ws_bill_customer_sk AS customer_sk
   FROM web_sales ws
   GROUP BY ws.ws_bill_customer_sk
),
store_only_customers AS (
   SELECT customer_sk FROM store_customers
   EXCEPT
   SELECT customer_sk FROM web_customers
),
common_customers AS (
   SELECT customer_sk FROM store_customers
   INTERSECT
   SELECT customer_sk FROM web_customers
),
union_customers AS (
   SELECT customer_sk FROM store_customers
   UNION ALL
   SELECT customer_sk FROM web_customers
),
customer_email_prefix AS (
   SELECT
     c.c_customer_sk,
     c.c_email_address,
     e.prefix_char
   FROM customer c
   CROSS JOIN LATERAL (
     SELECT substr(c.c_email_address, 1, 1) AS prefix_char
   ) e
)
SELECT
  f.customer_sk,
  f.store_net_paid,
  f.web_net_paid,
  cd.c_first_name,
  cd.c_last_name,
  ceb.prefix_char,
  ca.total_net_paid,
  ca.sales_cnt,
  ca.sales_rank,
  (SELECT SUM(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_catalog_page_sk = ca.cs_catalog_page_sk) AS page_total_ext_sales,
  CASE
    WHEN co.customer_sk IS NOT NULL THEN 'Both Channels'
    WHEN so.customer_sk IS NOT NULL THEN 'Store Only'
    ELSE 'Web Only'
  END AS channel_category
FROM full_sales f
LEFT JOIN catalog_sales_agg ca
  ON ca.cs_bill_customer_sk = f.customer_sk
LEFT JOIN customers_with_demo cd
  ON cd.c_customer_sk = f.customer_sk
LEFT JOIN customer_email_prefix ceb
  ON ceb.c_customer_sk = f.customer_sk
LEFT JOIN store_only_customers so
  ON so.customer_sk = f.customer_sk
LEFT JOIN common_customers co
  ON co.customer_sk = f.customer_sk
WHERE (f.store_net_paid IS NOT NULL OR f.web_net_paid IS NOT NULL)
  AND EXISTS (
        SELECT 1
        FROM catalog_sales csx
        WHERE csx.cs_bill_customer_sk = f.customer_sk
          AND csx.cs_ext_sales_price > 5000
      )
ORDER BY f.customer_sk
LIMIT 100
