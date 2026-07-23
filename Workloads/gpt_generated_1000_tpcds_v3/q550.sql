SELECT
    i.i_item_id,
    i.i_category,
    w.w_warehouse_name,
    d_sales.d_year AS sales_year,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_return_quantity) AS total_web_return_quantity,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_transactions,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i.i_category) AS avg_category_price
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sales.d_year = 2001
  AND i.i_current_price BETWEEN 50 AND 200
  AND hd_ss.hd_vehicle_count >= 2
  AND w.w_state = 'CA'
  AND cr.cr_return_quantity > 1
  AND cp.cp_department = 'Electronics'
GROUP BY
    i.i_item_id,
    i.i_category,
    w.w_warehouse_name,
    d_sales.d_year
ORDER BY total_sales_amount DESC
LIMIT 100
