WITH filtered_items AS (
   SELECT
       c.c_customer_id,
       i.i_category,
       i.i_brand,
       cs.cs_net_paid,
       ws.ws_net_paid,
       cr.cr_return_amount,
       sr.sr_return_amt,
       inv.inv_quantity_on_hand,
       sm.sm_type,
       t.t_hour,
       i.i_item_sk
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE i.i_category = 'Electronics'
     AND sm.sm_type = 'OVERNIGHT'
     AND t.t_hour BETWEEN 8 AND 20
     AND EXISTS (
         SELECT 1
         FROM inventory inv2
         WHERE inv2.inv_item_sk = i.i_item_sk
           AND inv2.inv_quantity_on_hand > 0
     )
)
SELECT
   i_category,
   i_brand,
   SUM(cs_net_paid) AS total_catalog_sales,
   SUM(ws_net_paid) AS total_web_sales,
   SUM(cr_return_amount) AS total_catalog_returns,
   SUM(sr_return_amt) AS total_store_returns,
   COUNT(DISTINCT c_customer_id) AS unique_customers,
   ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(cs_net_paid) DESC) AS sales_rank_in_category,
   CASE
       WHEN SUM(inv_quantity_on_hand) > 1000 THEN 'HIGH_STOCK'
       ELSE 'LOW_STOCK'
   END AS stock_level
FROM filtered_items
GROUP BY ROLLUP (i_category, i_brand)
ORDER BY i_category, i_brand
LIMIT 100
