/* Goal: Calculate total sales, quantity, and profit per item across catalog, web, and store channels, categorize profit level, and restrict to items that have inventory on hand, joining all relevant dimension tables. */
WITH item_inventory AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           inv.inv_warehouse_sk,
           inv.inv_quantity_on_hand
    FROM item i
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    w_cs.w_warehouse_name,
    (SUM(cs.cs_quantity) + SUM(ws.ws_quantity) + SUM(ss.ss_quantity)) AS total_quantity,
    (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) + SUM(ss.ss_net_paid)) AS total_net_paid,
    (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit)) AS total_profit,
    CASE
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit)) > 10000 THEN 'High'
        WHEN (SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit)) > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM item_inventory i
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_ws
    ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN customer_address ca_ws
    ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN customer c_cs
    ON cs.cs_bill_customer_sk = c_cs.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN customer_address ca_current
    ON c_cs.c_current_addr_sk = ca_current.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv_semi
    WHERE inv_semi.inv_item_sk = i.i_item_sk
      AND inv_semi.inv_quantity_on_hand > 0
      AND inv_semi.inv_warehouse_sk = w_cs.w_warehouse_sk
)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    w_cs.w_warehouse_name
ORDER BY total_profit DESC
LIMIT 100
