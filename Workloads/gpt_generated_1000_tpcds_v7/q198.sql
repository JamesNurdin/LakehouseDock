SELECT
    w_return.w_warehouse_name,
    cp.cp_department,
    d_ret.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders_returned,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer c_refunded
  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN tpcds.customer_address ca_refunded
  ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN tpcds.customer c_returning
  ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN tpcds.customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN tpcds.warehouse w_return
  ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
JOIN tpcds.inventory inv
  ON inv.inv_date_sk = d_ret.d_date_sk
JOIN tpcds.warehouse w_inventory
  ON inv.inv_warehouse_sk = w_inventory.w_warehouse_sk
WHERE d_ret.d_year = 2000
  AND w_return.w_warehouse_sq_ft > 500000
GROUP BY w_return.w_warehouse_name, cp.cp_department, d_ret.d_year
ORDER BY total_return_amount DESC
LIMIT 100
