SELECT
    item.i_category,
    call_center.cc_state,
    ship_mode.sm_type,
    time_dim.t_hour,
    SUM(store_sales.ss_net_paid) AS total_store_sales,
    SUM(web_sales.ws_net_paid) AS total_web_sales,
    SUM(catalog_returns.cr_return_amount) AS total_catalog_returns,
    SUM(web_returns.wr_return_amt) AS total_web_returns,
    AVG(store_sales.ss_quantity) AS avg_store_quantity,
    COUNT(DISTINCT store_sales.ss_ticket_number) AS distinct_store_tickets,
    MIN(store_sales.ss_sales_price) AS min_store_sales_price,
    MAX(store_sales.ss_sales_price) AS max_store_sales_price,
    (SELECT SUM(amount) FROM (SELECT cr_return_amount AS amount FROM catalog_returns UNION ALL SELECT wr_return_amt AS amount FROM web_returns) AS all_returns) AS total_all_return_amount,
    (SELECT COUNT(*) FROM web_returns wr_sub WHERE wr_sub.wr_return_amt > 200) AS high_web_return_count
FROM
    catalog_returns
    JOIN time_dim ON catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
    JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
    JOIN call_center ON catalog_returns.cr_call_center_sk = call_center.cc_call_center_sk
    JOIN catalog_page ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
    JOIN ship_mode ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
    JOIN warehouse ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
    JOIN store_sales ON store_sales.ss_item_sk = item.i_item_sk AND store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN web_sales ON web_sales.ws_item_sk = item.i_item_sk AND web_sales.ws_sold_time_sk = time_dim.t_time_sk AND web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk AND web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
    JOIN web_returns ON web_returns.wr_item_sk = web_sales.ws_item_sk AND web_returns.wr_order_number = web_sales.ws_order_number AND web_returns.wr_returned_time_sk = time_dim.t_time_sk
WHERE
    time_dim.t_hour BETWEEN 8 AND 17
    AND item.i_category = 'Electronics'
    AND call_center.cc_state = 'CA'
    AND ship_mode.sm_type = 'AIR'
    AND warehouse.w_state = 'TX'
    AND catalog_returns.cr_return_amount > 100.00
    AND store_sales.ss_quantity >= 2
    AND call_center.cc_rec_start_date <= DATE '2002-01-01'
    AND EXISTS (SELECT 1 FROM web_returns wr_sub WHERE wr_sub.wr_order_number = web_sales.ws_order_number AND wr_sub.wr_return_amt > 50)
GROUP BY
    item.i_category,
    call_center.cc_state,
    ship_mode.sm_type,
    time_dim.t_hour
ORDER BY
    total_store_sales DESC
LIMIT 100
