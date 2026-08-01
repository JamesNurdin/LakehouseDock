WITH combined_sales AS (
   SELECT
     d.d_year AS sales_year,
     i.i_brand AS brand,
     cd.cd_gender AS gender,
     p.p_promo_name AS promo_name,
     ss.ss_ext_sales_price AS sales_amount,
     ss.ss_net_profit AS profit_amount,
     ss.ss_quantity AS quantity
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2001
     AND i.i_manufact_id IN (338, 364)
     AND i.i_wholesale_cost > 5.00
     AND p.p_discount_active = 'Y'
     AND p.p_channel_email = 'Y'
     AND c.c_birth_month = 5
     AND cd.cd_marital_status = 'M'
   UNION ALL
   SELECT
     d.d_year AS sales_year,
     i.i_brand AS brand,
     cd.cd_gender AS gender,
     p.p_promo_name AS promo_name,
     ws.ws_ext_sales_price AS sales_amount,
     ws.ws_net_profit AS profit_amount,
     ws.ws_quantity AS quantity
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2001
     AND i.i_manufact_id IN (338, 364)
     AND i.i_wholesale_cost > 5.00
     AND p.p_discount_active = 'Y'
     AND p.p_channel_email = 'Y'
     AND c.c_birth_month = 5
     AND cd.cd_marital_status = 'M'
),
aggregated_sales AS (
   SELECT
     sales_year,
     brand,
     gender,
     promo_name,
     SUM(sales_amount) AS total_sales,
     SUM(profit_amount) AS total_profit,
     SUM(quantity) AS total_quantity
   FROM combined_sales
   GROUP BY sales_year, brand, gender, promo_name
),
brand_summary AS (
   SELECT
     brand,
     AVG(total_profit) AS avg_profit,
     SUM(total_sales) AS sum_sales,
     SUM(total_quantity) AS sum_quantity
   FROM aggregated_sales
   GROUP BY brand
)
SELECT
   bs.brand,
   bs.avg_profit,
   bs.sum_sales,
   bs.sum_quantity,
   (SELECT MAX(i3.i_current_price) FROM item i3 WHERE i3.i_brand = bs.brand) AS max_current_price
FROM brand_summary bs
WHERE bs.avg_profit > 2000
ORDER BY bs.avg_profit DESC
LIMIT 100
