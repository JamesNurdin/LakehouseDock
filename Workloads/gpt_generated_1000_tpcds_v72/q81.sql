WITH bill_sales AS (
   SELECT
      cust.c_customer_id,
      SUM(cs.cs_net_profit) AS total_profit,
      'bill_breakfast' AS source
   FROM catalog_sales cs
   JOIN customer cust
     ON cs.cs_bill_customer_sk = cust.c_customer_sk
   JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time = 'breakfast'
     AND cust.c_birth_year < 1970
   GROUP BY cust.c_customer_id
), web_sales AS (
   SELECT
      cust.c_customer_id,
      SUM(cs.cs_net_profit) AS total_profit,
      'web_high_images' AS source
   FROM catalog_sales cs
   JOIN customer cust
     ON cs.cs_ship_customer_sk = cust.c_customer_sk
   JOIN web_page wp
     ON wp.wp_customer_sk = cust.c_customer_sk
   WHERE wp.wp_image_count > 4
     AND cust.c_last_review_date > 2452500
   GROUP BY cust.c_customer_id
)
SELECT c_customer_id, total_profit, source
FROM bill_sales
UNION ALL
SELECT c_customer_id, total_profit, source
FROM web_sales
ORDER BY total_profit DESC
LIMIT 100
