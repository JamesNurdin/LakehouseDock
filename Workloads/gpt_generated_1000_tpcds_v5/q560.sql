WITH ss_agg AS (
   SELECT ss_item_sk,
          ss_store_sk,
          sum(ss_ext_sales_price) AS total_sales,
          sum(ss_quantity) AS total_qty
   FROM store_sales
   WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450500
   GROUP BY ss_item_sk, ss_store_sk
),
sr_agg AS (
   SELECT sr_item_sk,
          sr_store_sk,
          sum(sr_return_amt) AS total_return_amt,
          sum(sr_return_quantity) AS total_return_qty
   FROM store_returns
   WHERE sr_return_amt > 0
   GROUP BY sr_item_sk, sr_store_sk
),
cr_joined AS (
   SELECT cr.cr_item_sk,
          ca.ca_city,
          cd.cd_gender,
          sum(cr.cr_refunded_cash) AS total_refunded_cash,
          sum(cr.cr_fee) AS total_fee
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE ca.ca_city = 'Madison'
     AND cd.cd_gender = 'M'
     AND cr.cr_fee > 30
   GROUP BY cr.cr_item_sk, ca.ca_city, cd.cd_gender
),
joined_data AS (
   SELECT s.s_store_name,
          s.s_state,
          i.i_item_id,
          i.i_brand,
          ss.total_sales,
          ss.total_qty,
          COALESCE(sr.total_return_amt, 0) AS total_return_amt,
          COALESCE(sr.total_return_qty, 0) AS total_return_qty,
          COALESCE(cr.total_refunded_cash, 0) AS total_refunded_cash,
          CASE WHEN ss.total_sales > 50000 THEN 'High' ELSE 'Low' END AS sales_category
   FROM ss_agg ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN sr_agg sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_store_sk = sr.sr_store_sk
   LEFT JOIN cr_joined cr ON ss.ss_item_sk = cr.cr_item_sk
   WHERE i.i_brand = 'Brand#23'
     AND s.s_state = 'CA'
     AND ss.total_sales > 10000
     AND ss.total_qty > 50
)
SELECT
   s_store_name,
   s_state,
   COUNT(DISTINCT i_item_id) AS distinct_items_sold,
   SUM(total_sales) AS store_total_sales,
   SUM(total_return_amt) AS store_total_returns,
   SUM(total_refunded_cash) AS store_total_refunded_cash,
   AVG(total_sales) AS avg_item_sales,
   CASE WHEN SUM(total_sales) > 200000 THEN 'Top' ELSE 'Normal' END AS store_performance
FROM joined_data
GROUP BY s_store_name, s_state
HAVING SUM(total_sales) > 50000
ORDER BY store_total_sales DESC
LIMIT 100
