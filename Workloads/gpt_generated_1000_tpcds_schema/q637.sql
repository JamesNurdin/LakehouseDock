WITH store_agg AS (
   SELECT
       CASE WHEN store.s_state = 'CA' THEN 'CA' ELSE 'Other' END AS region,
       date_dim.d_year,
       SUM(store_sales.ss_net_paid) AS total_net_paid,
       AVG(store_sales.ss_ext_discount_amt) AS avg_discount,
       COUNT(DISTINCT store_sales.ss_ticket_number) AS orders,
       CASE WHEN SUM(store_sales.ss_quantity) > 1000 THEN 'High' ELSE 'Low' END AS volume_category
   FROM store_sales
   RIGHT OUTER JOIN store ON store_sales.ss_store_sk = store.s_store_sk
   JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
   JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
   JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
   JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
   JOIN customer_address ON store_sales.ss_addr_sk = customer_address.ca_address_sk
   LEFT JOIN store_returns ON store_returns.sr_ticket_number = store_sales.ss_ticket_number
   LEFT JOIN catalog_returns ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
   LEFT JOIN call_center ON catalog_returns.cr_call_center_sk = call_center.cc_call_center_sk
   LEFT JOIN catalog_page ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
   FULL OUTER JOIN inventory ON inventory.inv_date_sk = date_dim.d_date_sk
   FULL OUTER JOIN warehouse ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
   WHERE date_dim.d_year = 2001
     AND time_dim.t_am_pm = 'PM'
     AND store.s_state = 'TX'
     AND promotion.p_discount_active = 'Y'
     AND warehouse.w_state = 'TX'
     AND inventory.inv_quantity_on_hand > 0
     AND store.s_gmt_offset > (
         SELECT MAX(cc_gmt_offset) FROM call_center WHERE cc_state = 'CA'
     )
   GROUP BY CASE WHEN store.s_state = 'CA' THEN 'CA' ELSE 'Other' END, date_dim.d_year
),
web_agg AS (
   SELECT
       CASE WHEN web_page.wp_type = 'homepage' THEN 'Home' ELSE 'Other' END AS region,
       date_dim.d_year,
       SUM(web_sales.ws_net_paid) AS total_net_paid,
       AVG(web_sales.ws_ext_discount_amt) AS avg_discount,
       COUNT(DISTINCT web_sales.ws_order_number) AS orders,
       CASE WHEN SUM(web_sales.ws_quantity) > 500 THEN 'High' ELSE 'Low' END AS volume_category
   FROM web_sales
   JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
   JOIN time_dim ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
   JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
   JOIN warehouse ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
   LEFT JOIN web_page ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
   LEFT JOIN inventory ON inventory.inv_date_sk = date_dim.d_date_sk AND inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
   WHERE date_dim.d_year = 2001
     AND time_dim.t_am_pm = 'PM'
     AND promotion.p_discount_active = 'Y'
     AND warehouse.w_state = 'TX'
   GROUP BY CASE WHEN web_page.wp_type = 'homepage' THEN 'Home' ELSE 'Other' END, date_dim.d_year
)
SELECT
   region,
   d_year,
   total_net_paid,
   avg_discount,
   orders,
   volume_category,
   ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM (
   SELECT * FROM store_agg
   UNION DISTINCT
   SELECT * FROM web_agg
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
