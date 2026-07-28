WITH joined_data AS (
   SELECT
       i.i_item_sk,
       i.i_brand,
       i.i_category,
       i.i_current_price,
       cp.cp_department,
       w.w_state,
       r.r_reason_desc,
       inv.inv_quantity_on_hand,
       ss.ss_quantity AS sold_quantity,
       ss.ss_net_paid,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_net_loss,
       CASE 
           WHEN i.i_current_price < 20 THEN 'Low'
           WHEN i.i_current_price < 50 THEN 'Medium'
           ELSE 'High'
       END AS price_category
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_current_price BETWEEN 10 AND 100
     AND i.i_rec_start_date >= DATE '2000-01-01'
     AND w.w_state IN ('CA', 'TX')
     AND r.r_reason_desc NOT LIKE '%Gift%'
     AND inv.inv_quantity_on_hand < 500
     AND cp.cp_department = 'Electronics'
),
aggregated_per_item AS (
   SELECT
       i_item_sk,
       i_brand,
       i_category,
       price_category,
       cp_department,
       w_state,
       r_reason_desc,
       SUM(cr_return_amount) AS total_return_amount,
       SUM(cr_net_loss) AS total_net_loss,
       SUM(sold_quantity) AS total_sold_quantity,
       SUM(ss_net_paid) AS total_net_paid,
       COUNT(*) AS return_count
   FROM joined_data
   GROUP BY i_item_sk, i_brand, i_category, price_category, cp_department, w_state, r_reason_desc
)
SELECT
   i_brand,
   i_category,
   price_category,
   SUM(total_return_amount) AS brand_return_amount,
   AVG(total_net_loss) AS avg_net_loss,
   SUM(total_sold_quantity) AS brand_sold_qty,
   COUNT(DISTINCT i_item_sk) AS distinct_items
FROM aggregated_per_item api
WHERE NOT EXISTS (
    SELECT 1 FROM store_sales ss2
    WHERE ss2.ss_item_sk = api.i_item_sk
      AND ss2.ss_net_paid > 1000
)
GROUP BY i_brand, i_category, price_category
HAVING SUM(total_return_amount) > 500
ORDER BY avg_net_loss DESC
LIMIT 100
