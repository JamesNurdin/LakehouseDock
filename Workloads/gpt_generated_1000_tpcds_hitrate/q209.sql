WITH agg_sales AS (
   SELECT cs_bill_customer_sk,
          cs_catalog_page_sk,
          SUM(cs_ext_sales_price) AS total_sales,
          COUNT(*) AS cnt_sales
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
   WHERE cs_ext_discount_amt > 500
     AND cs_quantity BETWEEN 2 AND 10
   GROUP BY cs_bill_customer_sk, cs_catalog_page_sk
),
agg_page AS (
   SELECT cp_catalog_page_sk,
          MIN(cp_start_date_sk) AS min_start_sk
   FROM catalog_page
   WHERE cp_department = 'DEPARTMENT'
   GROUP BY cp_catalog_page_sk
),
unioned AS (
   SELECT d.d_year                     AS year,
          c.c_preferred_cust_flag      AS preferred_cust_flag,
          a.total_sales,
          a.cnt_sales
   FROM agg_sales a
   JOIN customer c ON a.cs_bill_customer_sk = c.c_customer_sk
   JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND d.d_year = 2000
     AND a.cs_bill_customer_sk NOT IN (
         SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'N'
     )
   UNION DISTINCT
   SELECT d2.d_year                    AS year,
          c2.c_preferred_cust_flag     AS preferred_cust_flag,
          a2.total_sales,
          a2.cnt_sales
   FROM agg_sales a2
   JOIN agg_page p ON a2.cs_catalog_page_sk = p.cp_catalog_page_sk
   JOIN date_dim d2 ON p.min_start_sk = d2.d_date_sk
   JOIN customer c2 ON a2.cs_bill_customer_sk = c2.c_customer_sk
   WHERE c2.c_preferred_cust_flag = 'Y'
     AND d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND a2.cs_bill_customer_sk NOT IN (
         SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'N'
     )
)
SELECT year,
       preferred_cust_flag,
       SUM(total_sales)      AS sum_total_sales,
       SUM(cnt_sales)        AS total_orders,
       COUNT(*)              AS distinct_rows
FROM unioned
GROUP BY year, preferred_cust_flag
ORDER BY sum_total_sales DESC
LIMIT 100
