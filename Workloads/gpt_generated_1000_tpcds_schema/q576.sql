/*
  Goal: Identify the top customers by total sales from both catalog and store channels, 
  categorizing their spend as High or Low, applying string filters on the customers' birth country, 
  and ranking them within each spend category.
*/
WITH
  cs_agg AS (
    SELECT
      c.c_customer_id,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      CASE WHEN SUM(cs.cs_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
      SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(c.c_birth_country, '^B')               -- countries starting with B
      AND c.c_birth_country LIKE '%A%'                      -- also contain an "A"
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
  ),
  cs_ranked AS (
    SELECT
      customer_name,
      sales_category,
      total_sales,
      ROW_NUMBER() OVER (PARTITION BY sales_category ORDER BY total_sales DESC) AS rank_in_category
    FROM cs_agg
  ),
  ss_agg AS (
    SELECT
      c.c_customer_id,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
      SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(c.c_birth_country, '^B')
      AND c.c_birth_country LIKE '%A%'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
  ),
  ss_ranked AS (
    SELECT
      customer_name,
      sales_category,
      total_sales,
      ROW_NUMBER() OVER (PARTITION BY sales_category ORDER BY total_sales DESC) AS rank_in_category
    FROM ss_agg
  )
SELECT *
FROM (
  SELECT customer_name, sales_category, total_sales, rank_in_category FROM cs_ranked
  UNION
  SELECT customer_name, sales_category, total_sales, rank_in_category FROM ss_ranked
) AS combined
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
