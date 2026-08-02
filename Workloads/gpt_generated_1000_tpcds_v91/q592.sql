SELECT
    w.w_county,
    i.i_brand,
    i.i_category,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(inv.inv_quantity_on_hand) AS total_on_hand,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_discount_amt) AS max_discount,
    (SELECT AVG(cs2.cs_net_paid_inc_ship_tax) FROM catalog_sales cs2) AS overall_avg_net_paid
FROM catalog_sales cs
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_county = 'Fairfield County'
  AND cs.cs_net_paid_inc_ship_tax > 5000
  AND inv.inv_quantity_on_hand > 100
  AND NOT EXISTS (
    SELECT 1 FROM inventory inv2
    WHERE inv2.inv_item_sk = inv.inv_item_sk
      AND inv2.inv_warehouse_sk = inv.inv_warehouse_sk
      AND inv2.inv_date_sk > inv.inv_date_sk
  )
GROUP BY ROLLUP (w.w_county, i.i_brand, i.i_category)
HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 20000
ORDER BY total_net_paid DESC
LIMIT 100
