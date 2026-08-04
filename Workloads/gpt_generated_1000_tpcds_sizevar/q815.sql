WITH filtered_items AS (
       SELECT i_item_sk,
              i_product_name,
              i_category,
              i_color
       FROM item
       TABLESAMPLE BERNOULLI (10)
       WHERE regexp_like(i_product_name, '\\b[A-Z]{2,}\\b')
         AND i_category LIKE 'Electronics%'
   ),
   agg_sales AS (
       SELECT
           COALESCE(cs.cs_order_number, -1) AS order_number,
           c.c_customer_id,
           d.d_year,
           fi.i_category,
           SUM(cs.cs_net_paid) AS total_net_paid,
           COUNT(cs.cs_order_number) AS orders
       FROM catalog_sales cs
       FULL OUTER JOIN customer c
           ON cs.cs_bill_customer_sk = c.c_customer_sk
       LEFT JOIN date_dim d
           ON cs.cs_sold_date_sk = d.d_date_sk
       INNER JOIN filtered_items fi
           ON cs.cs_item_sk = fi.i_item_sk
       WHERE (c.c_last_name LIKE 'S%' OR c.c_last_name IS NULL)
         AND (fi.i_product_name LIKE '%PRO%')
       GROUP BY
           COALESCE(cs.cs_order_number, -1),
           c.c_customer_id,
           d.d_year,
           fi.i_category
   )
SELECT
    order_number,
    c_customer_id,
    d_year,
    i_category,
    total_net_paid,
    orders,
    LAG(total_net_paid) OVER (PARTITION BY c_customer_id ORDER BY d_year) AS lag_total_net_paid
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
