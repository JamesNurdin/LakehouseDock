WITH ss_agg AS (
   SELECT
       ss_item_sk,
       ss_store_sk,
       ss_sold_date_sk,
       ss_sold_time_sk,
       ss_addr_sk,
       ss_cdemo_sk,
       SUM(ss_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt
   FROM store_sales
   WHERE ss_sold_date_sk IN (
       SELECT d_date_sk FROM date_dim
       WHERE d_year = 2001
         AND d_holiday = 'N'
         AND d_month_seq = 1200
   )
   GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk, ss_sold_time_sk, ss_addr_sk, ss_cdemo_sk
),
cr_agg AS (
   SELECT
       cr_item_sk,
       cr_returned_date_sk,
       cr_refunded_addr_sk,
       cr_refunded_cdemo_sk,
       SUM(cr_return_amount) AS total_return,
       COUNT(*) AS return_cnt
   FROM catalog_returns
   WHERE cr_returned_date_sk IN (
       SELECT d_date_sk FROM date_dim
       WHERE d_year = 2001
         AND d_holiday = 'N'
         AND d_month_seq = 1200
   )
   GROUP BY cr_item_sk, cr_returned_date_sk, cr_refunded_addr_sk, cr_refunded_cdemo_sk
),
common_items AS (
   SELECT ss_item_sk AS item_sk FROM ss_agg
   INTERSECT
   SELECT cr_item_sk FROM cr_agg
)
SELECT
   d.d_year,
   i.i_category,
   i.i_brand,
   s.s_store_name,
   cd.cd_credit_rating,
   ca.ca_state,
   wp.wp_type,
   COUNT(DISTINCT ss_agg.ss_store_sk) AS num_stores,
   SUM(ss_agg.total_sales) AS sum_sales,
   SUM(cr_agg.total_return) AS sum_returns,
   AVG(ss_agg.total_sales) - AVG(cr_agg.total_return) AS avg_sales_minus_return,
   MIN(ss_agg.total_sales) AS min_sales,
   MAX(ss_agg.total_sales) AS max_sales
FROM common_items ci
JOIN ss_agg ON ci.item_sk = ss_agg.ss_item_sk
JOIN cr_agg ON ci.item_sk = cr_agg.cr_item_sk
JOIN item i ON ci.item_sk = i.i_item_sk
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN customer_address ca ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp ON d.d_date_sk = wp.wp_creation_date_sk
WHERE i.i_manufact = 'antiablecally'
  AND cd.cd_credit_rating = 'Good      '
  AND ca.ca_country = 'United States'
GROUP BY d.d_year, i.i_category, i.i_brand, s.s_store_name, cd.cd_credit_rating, ca.ca_state, wp.wp_type
ORDER BY sum_sales DESC
LIMIT 100
