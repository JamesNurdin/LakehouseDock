WITH sales_union AS (
   SELECT
       ss_sold_date_sk AS date_sk,
       ss_sold_time_sk AS time_sk,
       ss_item_sk AS item_sk,
       ss_customer_sk AS customer_sk,
       ss_store_sk AS channel_id,
       'store' AS channel,
       ss_quantity AS quantity,
       ss_net_paid AS net_paid,
       ss_ext_discount_amt AS discount,
       ss_ext_sales_price AS ext_sales_price,
       ss_net_profit AS net_profit,
       ss_promo_sk AS promo_sk
   FROM store_sales
   UNION ALL
   SELECT
       cs_sold_date_sk,
       cs_sold_time_sk,
       cs_item_sk,
       cs_bill_customer_sk,
       cs_call_center_sk,
       'catalog',
       cs_quantity,
       cs_net_paid,
       cs_ext_discount_amt,
       cs_ext_sales_price,
       cs_net_profit,
       cs_promo_sk
   FROM catalog_sales
   UNION ALL
   SELECT
       ws_sold_date_sk,
       ws_sold_time_sk,
       ws_item_sk,
       ws_bill_customer_sk,
       ws_web_page_sk,
       'web',
       ws_quantity,
       ws_net_paid,
       ws_ext_discount_amt,
       ws_ext_sales_price,
       ws_net_profit,
       ws_promo_sk
   FROM web_sales
),
sales_augmented AS (
   SELECT
       su.*,
       d.d_year,
       i.i_category,
       i.i_class,
       i.i_brand,
       CASE WHEN su.promo_sk IS NULL THEN false ELSE true END AS is_promo
   FROM sales_union su
   LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
   LEFT JOIN item i ON su.item_sk = i.i_item_sk
),
aggregated_sales AS (
   SELECT
       d_year,
       channel,
       i_category,
       i_brand,
       SUM(ext_sales_price) AS total_sales,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_profit,
       AVG(discount) AS avg_discount,
       COUNT(DISTINCT customer_sk) AS distinct_customers,
       COUNT(DISTINCT item_sk) AS distinct_items,
       SUM(CASE WHEN is_promo THEN ext_sales_price ELSE 0 END) AS promo_sales,
       SUM(CASE WHEN NOT is_promo THEN ext_sales_price ELSE 0 END) AS nonpromo_sales
   FROM sales_augmented
   WHERE d_year BETWEEN 2001 AND 2003
   GROUP BY ROLLUP (d_year, channel, i_category, i_brand)
   HAVING SUM(ext_sales_price) > 10000
)
SELECT
   d_year,
   channel,
   i_category,
   i_brand,
   total_sales,
   total_net_paid,
   total_profit,
   avg_discount,
   distinct_customers,
   distinct_items,
   promo_sales,
   nonpromo_sales,
   ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_sales DESC) AS sales_rank
FROM aggregated_sales
ORDER BY d_year, channel, total_sales DESC
LIMIT 100
