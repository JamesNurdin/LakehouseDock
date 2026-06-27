SELECT
    di.d_year,
    extract(month FROM di.d_date) AS month,
    i.i_category,
    w.w_warehouse_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM store_sales ss
JOIN date_dim di ON ss.ss_sold_date_sk = di.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_date_sk = di.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE di.d_date >= DATE '2001-01-01' AND di.d_date < DATE '2002-01-01'
GROUP BY di.d_year,
         extract(month FROM di.d_date),
         i.i_category,
         w.w_warehouse_name
ORDER BY di.d_year, month, total_net_profit DESC
