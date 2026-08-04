WITH first_part AS (
   SELECT
       s.s_store_id,
       i.i_item_id,
       ca.ca_city,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   WHERE s.s_country = 'United States'
     AND i.i_wholesale_cost > 10
     AND inv.inv_quantity_on_hand > 200
     AND s.s_tax_percentage > (
         SELECT AVG(s2.s_tax_percentage)
         FROM store s2
         WHERE s2.s_country = 'United States'
     )
   GROUP BY s.s_store_id, i.i_item_id, ca.ca_city
),
second_part AS (
   SELECT
       s.s_store_id,
       i.i_item_id,
       ca.ca_city,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt
   FROM store_sales ss TABLESAMPLE BERNOULLI (5)
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   WHERE s.s_state = 'CA'
     AND i.i_class_id = 12
     AND inv.inv_warehouse_sk = 5
   GROUP BY s.s_store_id, i.i_item_id, ca.ca_city
),
unioned AS (
   SELECT * FROM first_part
   UNION DISTINCT
   SELECT * FROM second_part
)
SELECT
   ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
   s_store_id,
   i_item_id,
   ca_city,
   total_sales,
   sales_cnt
FROM unioned
ORDER BY total_sales DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
