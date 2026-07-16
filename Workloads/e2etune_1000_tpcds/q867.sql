WITH web_page_counts AS (
    SELECT wp.wp_customer_sk AS customer_sk,
           COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
),
inventory_agg AS (
    SELECT inv.inv_item_sk,
           inv.inv_date_sk,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
)
SELECT cp.cp_type,
       sm.sm_carrier,
       i.i_category,
       i.i_brand,
       COUNT(cr.cr_order_number) AS num_returns,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_quantity) AS total_return_qty,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(inv_agg.total_on_hand) AS avg_inventory_on_hand,
       (SUM(cr.cr_return_quantity) * 1.0) / NULLIF(AVG(inv_agg.total_on_hand), 0) AS return_to_stock_ratio,
       AVG(wp_counts.num_web_pages) AS avg_customer_web_pages,
       RANK() OVER (PARTITION BY cp.cp_type ORDER BY SUM(cr.cr_net_loss) DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inventory_agg inv_agg ON inv_agg.inv_item_sk = i.i_item_sk AND inv_agg.inv_date_sk = cr.cr_returned_date_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN web_page_counts wp_counts ON wp_counts.customer_sk = c.c_customer_sk
WHERE cp.cp_type = 'quarterly'
  AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY cp.cp_type, sm.sm_carrier, i.i_category, i.i_brand
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
