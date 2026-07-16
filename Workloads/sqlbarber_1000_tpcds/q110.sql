SELECT w.w_warehouse_name,
       cs.cs_sold_date_sk,
       SUM(cs.cs_net_paid) AS total_sales,
       AVG(inv.inv_quantity_on_hand) AS avg_inventory
FROM catalog_sales cs
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_sold_date_sk = 2450856
  AND inv.inv_date_sk = 2450878
GROUP BY w.w_warehouse_name, cs.cs_sold_date_sk
ORDER BY total_sales DESC
