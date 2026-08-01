WITH
all_customers AS (
   SELECT DISTINCT c.c_customer_sk
   FROM customer c
   WHERE c.c_birth_year BETWEEN 1960 AND 1980
   UNION
   SELECT DISTINCT wp.wp_customer_sk
   FROM web_page wp
   WHERE wp.wp_type = 'article'
),
high_price_item_keys AS (
   SELECT i.i_item_sk
   FROM item i
   WHERE i.i_current_price > 100
   INTERSECT
   SELECT ss.ss_item_sk
   FROM store_sales ss
   WHERE ss.ss_sales_price > 5
),
sales_agg AS (
   SELECT
     i.i_item_sk,
     i.i_category,
     d.d_month_seq,
     SUM(ss.ss_net_profit) AS category_month_profit,
     SUM(ss.ss_quantity) AS category_month_quantity,
     COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
     AVG(ss.ss_sales_price) AS avg_sales_price,
     MIN(ss.ss_sold_date_sk) AS min_sold_date_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE
     d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND ca.ca_county = 'York County'
     AND ca.ca_gmt_offset > 0
     AND i.i_category = 'Sports'
     AND t.t_meal_time = 'Lunch'
     AND EXISTS (SELECT 1 FROM all_customers ac WHERE ac.c_customer_sk = c.c_customer_sk)
   GROUP BY
     i.i_item_sk,
     i.i_category,
     d.d_month_seq
   HAVING
     SUM(ss.ss_quantity) > 100
)
SELECT
  sa.i_category,
  AVG(sa.category_month_profit) AS avg_monthly_profit,
  SUM(sa.category_month_quantity) AS total_quantity,
  SUM(sa.distinct_customers) AS total_distinct_customers
FROM sales_agg sa
WHERE NOT EXISTS (
   SELECT 1
   FROM high_price_item_keys hp
   WHERE hp.i_item_sk = sa.i_item_sk
)
GROUP BY sa.i_category
HAVING AVG(sa.category_month_profit) > (
   SELECT AVG(ss2.ss_net_profit)
   FROM store_sales ss2
   JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
   WHERE d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
ORDER BY avg_monthly_profit DESC
LIMIT 100
