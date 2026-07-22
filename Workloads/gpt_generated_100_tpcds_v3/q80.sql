/*
Goal: Calculate yearly profit and return metrics for 2001, broken down by warehouse, ship mode, and item category, by combining catalog sales, store sales, returns, and inventory data.
*/
SELECT
    w.w_warehouse_name,
    sm.sm_type,
    d_sold.d_year,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
FROM
    catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN customer cust_store
        ON ss.ss_customer_sk = cust_store.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN customer cust_refunded
        ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
    LEFT JOIN customer cust_returning
        ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
    LEFT JOIN ship_mode sm_ret
        ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    LEFT JOIN warehouse w_ret
        ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year = 2001
GROUP BY
    w.w_warehouse_name,
    sm.sm_type,
    d_sold.d_year,
    i.i_category
ORDER BY
    w.w_warehouse_name,
    sm.sm_type,
    d_sold.d_year,
    i.i_category
