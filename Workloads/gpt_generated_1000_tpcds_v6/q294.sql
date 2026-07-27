SELECT
    i.i_brand,
    ca.ca_state,
    sm.sm_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    SUM(ss.ss_quantity) AS total_store_quantity,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(cr.cr_return_amount) AS total_return_amount,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_address ca
  ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
 AND ss.ss_customer_sk = c.c_customer_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
  AND i.i_wholesale_cost > 1.00
  AND ca.ca_state = 'CA'
  AND wp.wp_image_count >= 3
  AND sm.sm_type = 'AIR'
GROUP BY ROLLUP (i.i_brand, ca.ca_state, sm.sm_type)
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
