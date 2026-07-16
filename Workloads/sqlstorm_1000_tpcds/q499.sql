WITH 
all_customers AS (
   SELECT ss_customer_sk AS customer_sk FROM store_sales
   UNION
   SELECT cs_bill_customer_sk FROM catalog_sales
   UNION
   SELECT ws_bill_customer_sk FROM web_sales
),
store_agg AS (
   SELECT ss_customer_sk AS customer_sk,
          SUM(ss_net_paid) AS total_store_sales,
          SUM(ss_ext_discount_amt) AS total_store_discount,
          COUNT(DISTINCT ss_ticket_number) AS num_store_orders
   FROM store_sales
   GROUP BY ss_customer_sk
),
catalog_agg AS (
   SELECT cs_bill_customer_sk AS customer_sk,
          SUM(cs_net_paid) AS total_catalog_sales,
          COUNT(DISTINCT cs_order_number) AS num_catalog_orders
   FROM catalog_sales
   GROUP BY cs_bill_customer_sk
),
web_agg AS (
   SELECT ws_bill_customer_sk AS customer_sk,
          SUM(ws_net_paid) AS total_web_sales,
          COUNT(DISTINCT ws_order_number) AS num_web_orders
   FROM web_sales
   GROUP BY ws_bill_customer_sk
),
combined_sales AS (
   SELECT ac.customer_sk,
          COALESCE(sa.total_store_sales, 0) AS total_store_sales,
          COALESCE(sa.total_store_discount, 0) AS total_store_discount,
          COALESCE(sa.num_store_orders, 0) AS num_store_orders,
          COALESCE(ca.total_catalog_sales, 0) AS total_catalog_sales,
          COALESCE(ca.num_catalog_orders, 0) AS num_catalog_orders,
          COALESCE(wa.total_web_sales, 0) AS total_web_sales,
          COALESCE(wa.num_web_orders, 0) AS num_web_orders,
          COALESCE(sa.total_store_sales, 0) + COALESCE(ca.total_catalog_sales, 0) + COALESCE(wa.total_web_sales, 0) AS total_all_sales
   FROM all_customers ac
   LEFT OUTER JOIN store_agg sa ON ac.customer_sk = sa.customer_sk
   LEFT OUTER JOIN catalog_agg ca ON ac.customer_sk = ca.customer_sk
   LEFT OUTER JOIN web_agg wa ON ac.customer_sk = wa.customer_sk
),
ranked_customers AS (
   SELECT cs.customer_sk,
          cs.total_all_sales,
          ROW_NUMBER() OVER (ORDER BY cs.total_all_sales DESC) AS sales_rank,
          NTILE(10) OVER (ORDER BY cs.total_all_sales DESC) AS sales_decile
   FROM combined_sales cs
),
customer_details AS (
   SELECT c.c_customer_sk,
          c.c_first_name,
          c.c_last_name,
          c.c_preferred_cust_flag,
          ca.ca_city,
          ca.ca_state,
          cd.cd_gender,
          cd.cd_marital_status,
          cd.cd_education_status,
          d.d_year,
          d.d_month_seq,
          (SELECT SUM(ss.ss_net_paid)
             FROM store_sales ss
            WHERE ss.ss_customer_sk = c.c_customer_sk
              AND ss.ss_sold_date_sk = d.d_date_sk) AS sales_on_date
   FROM customer c
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
),
final AS (
   SELECT rc.sales_rank,
          rc.sales_decile,
          cd.c_customer_sk,
          cd.c_first_name || ' ' || cd.c_last_name AS full_name,
          cd.c_preferred_cust_flag,
          cd.ca_city,
          cd.ca_state,
          cd.cd_gender,
          cd.cd_marital_status,
          cd.cd_education_status,
          rc.total_all_sales,
          cd.sales_on_date,
          (rc.total_all_sales - COALESCE(cd.sales_on_date, 0)) / NULLIF(rc.total_all_sales, 0) AS proportion_excluding_first_sales,
          CASE
             WHEN rc.total_all_sales > 100000 THEN 'Platinum'
             WHEN rc.total_all_sales > 50000 THEN 'Gold'
             WHEN rc.total_all_sales > 20000 THEN 'Silver'
             ELSE 'Bronze'
          END AS customer_tier,
          CONCAT('CUST', LPAD(CAST(cd.c_customer_sk AS VARCHAR), 8, '0')) AS customer_key
   FROM ranked_customers rc
   JOIN customer_details cd ON rc.customer_sk = cd.c_customer_sk
   WHERE rc.sales_rank <= 1000
     AND (rc.total_all_sales IS NOT NULL OR cd.sales_on_date IS NOT NULL)
     AND (cd.c_preferred_cust_flag = 'Y' OR cd.cd_gender = 'M')
     AND rc.total_all_sales > 0
)
SELECT *
FROM final
WHERE customer_tier <> 'Bronze'
UNION ALL
SELECT
   -1 AS sales_rank,
   -1 AS sales_decile,
   NULL AS c_customer_sk,
   'TOTAL' AS full_name,
   NULL AS c_preferred_cust_flag,
   NULL AS ca_city,
   NULL AS ca_state,
   NULL AS cd_gender,
   NULL AS cd_marital_status,
   NULL AS cd_education_status,
   SUM(total_all_sales) AS total_all_sales,
   NULL AS sales_on_date,
   NULL AS proportion_excluding_first_sales,
   'Summary' AS customer_tier,
   NULL AS customer_key
FROM final
WHERE customer_tier <> 'Bronze'
