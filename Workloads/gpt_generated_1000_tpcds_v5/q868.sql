SELECT
    d_sold.d_year AS sale_year,
    i_item.i_category AS item_category,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_qty,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    COALESCE(s.s_store_name, 'No Store') AS store_name
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i_item
    ON cs.cs_item_sk = i_item.i_item_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w_sales
    ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN inventory inv
    ON inv.inv_item_sk = i_item.i_item_sk
   AND inv.inv_warehouse_sk = w_sales.w_warehouse_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    i_item.i_category,
    s.s_store_name
ORDER BY
    total_net_profit DESC,
    sale_year,
    item_category
LIMIT 100
