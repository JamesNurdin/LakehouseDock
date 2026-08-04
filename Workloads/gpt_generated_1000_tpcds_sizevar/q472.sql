WITH filtered_customers AS (
   SELECT c.c_customer_sk,
          CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
          c.c_birth_country
   FROM tpcds.customer c
   WHERE c.c_birth_country LIKE '%A%'
     AND regexp_like(c.c_birth_country, '^.*[AEIOU].*$')
),
order_sales AS (
   SELECT cs.cs_order_number,
          cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_item_sk,
          cs.cs_net_profit,
          i.i_product_name,
          i.i_item_desc,
          cs.cs_ext_sales_price,
          (
             SELECT SUM(cr.cr_return_amount)
             FROM tpcds.catalog_returns cr
             WHERE cr.cr_order_number = cs.cs_order_number
          ) AS total_return_amount
   FROM tpcds.catalog_sales cs
   JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
   JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '[0-9]{2}')
),
order_sales_ship AS (
   SELECT cs.cs_order_number,
          cs.cs_ship_customer_sk AS customer_sk,
          cs.cs_item_sk,
          cs.cs_net_profit,
          i.i_product_name,
          i.i_item_desc,
          cs.cs_ext_sales_price,
          (
             SELECT SUM(cr.cr_return_amount)
             FROM tpcds.catalog_returns cr
             WHERE cr.cr_order_number = cs.cs_order_number
          ) AS total_return_amount
   FROM tpcds.catalog_sales cs
   JOIN filtered_customers fc ON cs.cs_ship_customer_sk = fc.c_customer_sk
   JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '[0-9]{2}')
),
union_sales AS (
   SELECT cs_order_number, customer_sk, cs_net_profit, total_return_amount
   FROM order_sales
   UNION
   SELECT cs_order_number, customer_sk, cs_net_profit, total_return_amount
   FROM order_sales_ship
),
final_set AS (
   SELECT us.cs_order_number,
          us.customer_sk,
          us.cs_net_profit,
          us.total_return_amount,
          CONCAT('Order_', CAST(us.cs_order_number AS VARCHAR)) AS order_label,
          SUBSTRING(i.i_product_name, 1, 10) AS product_prefix
   FROM union_sales us
   JOIN tpcds.catalog_sales cs ON us.cs_order_number = cs.cs_order_number
   JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
   WHERE us.cs_net_profit > 0
)
SELECT f.cs_order_number,
       f.customer_sk,
       f.cs_net_profit,
       f.total_return_amount,
       f.order_label,
       f.product_prefix
FROM final_set f
INTERSECT
SELECT cs.cs_order_number,
       cs.cs_bill_customer_sk,
       cs.cs_net_profit,
       (
          SELECT SUM(cr.cr_return_amount)
          FROM tpcds.catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
       ) AS total_return_amount,
       CONCAT('Order_', CAST(cs.cs_order_number AS VARCHAR)) AS order_label,
       SUBSTRING(i.i_product_name, 1, 10) AS product_prefix
FROM tpcds.catalog_sales cs
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_ext_sales_price > 120.00
ORDER BY cs_net_profit DESC
LIMIT 100
