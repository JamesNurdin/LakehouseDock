WITH sampled_sales AS (
       SELECT *
       FROM store_sales TABLESAMPLE BERNOULLI (10)
       WHERE ss_quantity > 1
   ),
   intersect_items AS (
       SELECT cs_item_sk AS item_sk FROM catalog_sales
       INTERSECT
       SELECT ss_item_sk FROM store_sales
   )
SELECT
   d.d_year,
   s.s_store_name,
   i.i_category,
   COUNT(DISTINCT ss.ss_ticket_number) AS orders,
   SUM(ss.ss_net_paid) AS total_net_paid,
   AVG(cs.cs_net_profit) AS avg_profit,
   MIN(cr.cr_return_amount) AS min_return_amount,
   MAX(cr.cr_return_amount) AS max_return_amount
FROM sampled_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                      AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND sm.sm_ship_mode_id = 'AAAAAAAABBAAAAA'
  AND cp.cp_department = 'Electronics'
  AND c.c_birth_month = 7
  AND ss.ss_net_paid > 100.00
  AND ss.ss_ticket_number NOT IN (SELECT cr_order_number FROM catalog_returns)
  AND ss.ss_item_sk IN (SELECT item_sk FROM intersect_items)
GROUP BY d.d_year, s.s_store_name, i.i_category
ORDER BY total_net_paid DESC
LIMIT 100
