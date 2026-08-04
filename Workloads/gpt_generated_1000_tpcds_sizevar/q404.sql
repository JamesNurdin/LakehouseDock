WITH
promo_sales AS (
   SELECT
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      i.i_category,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS order_cnt,
      RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS category_sales_rank
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2021
     AND i.i_item_desc LIKE '%PROMO%'
     AND regexp_like(p.p_promo_name, '^Summer.*')
   GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk, i.i_category
),
nonpromo_sales AS (
   SELECT
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2021
     AND i.i_item_desc LIKE '%PROMO%'
     AND p.p_promo_sk IS NULL
   GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
)
SELECT
   ps.cs_bill_customer_sk,
   c.c_first_name,
   c.c_last_name,
   ps.total_sales,
   ps.order_cnt,
   ps.category_sales_rank
FROM promo_sales ps
JOIN customer c ON ps.cs_bill_customer_sk = c.c_customer_sk
EXCEPT
SELECT
   ns.cs_bill_customer_sk,
   c2.c_first_name,
   c2.c_last_name,
   ns.total_sales,
   CAST(NULL AS integer) AS order_cnt,
   CAST(NULL AS integer) AS category_sales_rank
FROM nonpromo_sales ns
JOIN customer c2 ON ns.cs_bill_customer_sk = c2.c_customer_sk
ORDER BY total_sales DESC
LIMIT 100
