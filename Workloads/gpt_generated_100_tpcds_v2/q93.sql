SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sk IN (13, 20)
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year, d.d_month_seq
ORDER BY w.w_warehouse_id, d.d_year, d.d_month_seq
