WITH sales AS (
   SELECT
       i.i_item_sk,
       i.i_brand,
       i.i_category,
       i.i_manager_id,
       ss.ss_ext_sales_price,
       ss.ss_ticket_number,
       ss.ss_sold_date_sk
   FROM item i
   RIGHT OUTER JOIN store_sales ss
       ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_manager_id IN (3, 23, 64)                     -- manager filter
     AND i.i_brand_id = 7004003                           -- brand filter
     AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500   -- surrogate date range
),
returns AS (
   SELECT
       i.i_item_sk,
       cc.cc_name,
       cp.cp_catalog_number,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_returned_date_sk,
       cr.cr_call_center_sk,
       c.c_email_address,
       wp.wp_type,
       hd.hd_vehicle_count
   FROM catalog_returns cr
   JOIN item i
       ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c
       ON cr.cr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp
       ON wp.wp_customer_sk = c.c_customer_sk
   LEFT JOIN household_demographics hd
       ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cc.cc_manager = 'Mark Hightower'                 -- manager name filter
     AND cp.cp_type = '1'                                 -- catalog page type filter
     AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450500
     AND c.c_email_address LIKE '%@Y3Etqyv3.org'        -- email domain filter
     AND wp.wp_type = 'content'                          -- web page type filter
     AND hd.hd_vehicle_count > 1                         -- household vehicle count filter
),
intersect_items AS (
   SELECT i_item_sk FROM sales
   INTERSECT
   SELECT i_item_sk FROM returns
),
aggregated AS (
   SELECT
       s.i_item_sk,
       s.i_brand,
       s.i_category,
       cc.cc_name,
       SUM(s.ss_ext_sales_price) AS total_sales,
       SUM(r.cr_return_amount) AS total_returns,
       COUNT(DISTINCT s.ss_ticket_number) AS sales_transactions,
       COUNT(DISTINCT r.cr_return_quantity) AS return_transactions
   FROM sales s
   LEFT JOIN returns r
       ON s.i_item_sk = r.i_item_sk
   LEFT JOIN call_center cc
       ON r.cr_call_center_sk = cc.cc_call_center_sk
   WHERE s.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
   GROUP BY s.i_item_sk, s.i_brand, s.i_category, cc.cc_name
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC) AS rnk
   FROM aggregated
)
SELECT
   i_item_sk,
   i_brand,
   i_category,
   cc_name,
   total_sales,
   total_returns,
   sales_transactions,
   return_transactions,
   rnk
FROM ranked
WHERE rnk <= 5
ORDER BY cc_name, rnk
LIMIT 100
