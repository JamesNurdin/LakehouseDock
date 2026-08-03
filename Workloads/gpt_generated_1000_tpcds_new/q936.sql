WITH
    intersected_warehouses AS (
        SELECT ws_warehouse_sk FROM web_sales WHERE ws_ext_sales_price > 5000
        INTERSECT
        SELECT ws_warehouse_sk FROM web_sales WHERE ws_quantity > 10
    ),
    base_agg AS (
        SELECT
            ws.ws_warehouse_sk,
            w.w_state,
            w.w_zip,
            ca_bill.ca_country AS bill_country,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit,
            AVG(ws.ws_ext_list_price) AS avg_list_price,
            COUNT(*) AS order_cnt
        FROM web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        WHERE w.w_state = 'CA'
          AND w.w_zip = '35709'
          AND ca_bill.ca_country = 'United States'
          AND ws.ws_ext_list_price > 1000
          AND ws.ws_warehouse_sk IN (SELECT ws_warehouse_sk FROM intersected_warehouses)
        GROUP BY ws.ws_warehouse_sk, w.w_state, w.w_zip, ca_bill.ca_country
        HAVING SUM(ws.ws_ext_sales_price) > 20000
    )
SELECT
    b.w_state,
    b.w_zip,
    b.bill_country,
    b.total_sales,
    b.total_profit,
    b.avg_list_price,
    b.order_cnt,
    CASE
        WHEN b.total_profit / NULLIF(b.total_sales, 0) > 0.20 THEN 'High'
        WHEN b.total_profit / NULLIF(b.total_sales, 0) > 0.10 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_warehouse_sk = b.ws_warehouse_sk) AS total_orders_all,
    (SELECT MAX(ws_ext_list_price) FROM web_sales) AS global_max_list_price,
    CASE WHEN b.avg_list_price > (SELECT MAX(ws_ext_list_price) FROM web_sales) THEN 1 ELSE 0 END AS above_global_max_flag
FROM base_agg b
ORDER BY b.total_sales DESC
OFFSET 0 FETCH FIRST 10 ROWS ONLY
