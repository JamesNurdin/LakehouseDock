WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_item_sk,
       ss.ss_customer_sk,
       ss.ss_quantity,
       ss.ss_sales_price,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       i.i_category,
       i.i_brand,
       i.i_product_name,
       t.t_hour,
       t.t_minute,
       t.t_second,
       c.c_birth_year,
       cd.cd_gender,
       cd.cd_marital_status,
       wp.wp_char_count,
       wp.wp_link_count
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   LEFT OUTER JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE t.t_hour = 12
     AND t.t_minute = 4
     AND i.i_brand = 'Brand#23'
     AND c.c_birth_year = 1975
     AND ss.ss_quantity > 2
     AND (wp.wp_char_count > 1500 OR wp.wp_char_count IS NULL)
     AND EXISTS (
         SELECT 1
         FROM web_page wp2
         WHERE wp2.wp_customer_sk = c.c_customer_sk
           AND wp2.wp_link_count > 10
     )
),

agg AS (
   SELECT
       i_category                         AS category,
       i_brand                            AS brand,
       t_hour                             AS hour,
       cd_gender                          AS gender,
       SUM(ss_ext_sales_price)            AS total_sales,
       AVG(ss_net_profit)                 AS avg_profit,
       SUM(CASE WHEN cd_gender = 'M' THEN ss_quantity ELSE 0 END) AS male_qty,
       (
           SELECT AVG(ss2.ss_sales_price)
           FROM store_sales ss2
           JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
           WHERE i2.i_category = i_category
       )                                 AS category_avg_price
   FROM base
   GROUP BY i_category, i_brand, t_hour, cd_gender
),

unioned AS (
   SELECT * FROM agg WHERE total_sales > 10000
   UNION ALL
   SELECT * FROM agg WHERE total_sales <= 10000
)
SELECT
   category,
   brand,
   hour,
   gender,
   total_sales,
   avg_profit,
   male_qty,
   category_avg_price
FROM unioned
ORDER BY total_sales DESC
LIMIT 100
