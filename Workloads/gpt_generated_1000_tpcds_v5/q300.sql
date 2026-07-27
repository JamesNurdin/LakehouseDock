/*
Goal: Produce a profit and inventory summary per warehouse city and catalog department, combining catalog sales and web sales data. The query joins all nine selected tables, reuses the customer dimension twice (billing and shipping), and filters web sales to only those orders that have at least one returned item using an EXISTS semi‑join.
*/
SELECT
    w.w_city AS warehouse_city,
    cp.cp_department AS catalog_department,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = ws.ws_order_number
      AND wr.wr_return_quantity > 0
)
GROUP BY w.w_city, cp.cp_department
ORDER BY total_catalog_profit DESC
LIMIT 100
