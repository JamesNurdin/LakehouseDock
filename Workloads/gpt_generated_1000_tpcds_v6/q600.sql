WITH agg_inventory AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    cp.cp_department,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_catalog_returns,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(COALESCE(ai.total_qty, 0)) AS total_inventory_qty,
    (SELECT SUM(ai2.total_qty) FROM agg_inventory ai2) AS grand_total_inventory,
    CASE WHEN w.w_warehouse_sq_ft > 100000 THEN 'Large' ELSE 'Small' END AS warehouse_size_category
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                      AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN store_sales ss ON ss.ss_customer_sk = c_bill.c_customer_sk
                     AND ss.ss_sold_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_item_sk = ss.ss_item_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
                     AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_item_sk = ws.ws_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN agg_inventory ai ON ai.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND cp.cp_department = 'Sports'
  AND EXISTS (
        SELECT 1 FROM store_sales ss_check
        WHERE ss_check.ss_customer_sk = c_bill.c_customer_sk
          AND ss_check.ss_quantity > 10
    )
GROUP BY d.d_year,
         w.w_warehouse_name,
         cp.cp_department,
         wp.wp_type,
         w.w_warehouse_sq_ft
ORDER BY total_catalog_sales DESC
LIMIT 100
