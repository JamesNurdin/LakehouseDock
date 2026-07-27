WITH sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_salutation AS salutation,
        w.w_warehouse_name AS warehouse_name,
        cp.cp_department AS department,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        SUM(CASE WHEN ss.ss_list_price > 50 THEN ss.ss_net_paid ELSE 0 END) AS high_price_store_sales,
        SUM(CASE WHEN ws.ws_list_price > 50 THEN ws.ws_net_paid ELSE 0 END) AS high_price_web_sales
    FROM customer c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_warehouse_sq_ft BETWEEN 500000 AND 900000
        AND w.w_suite_number LIKE 'Suite %'
        AND w.w_zip IN ('35709', '46098')
        AND ss.ss_list_price > 20
        AND ws.ws_list_price > 20
        AND c.c_salutation IN ('Mr.', 'Ms.')
        AND c.c_last_review_date > 2452300
    GROUP BY
        c.c_customer_id,
        c.c_salutation,
        w.w_warehouse_name,
        cp.cp_department
)
SELECT
    customer_id,
    salutation,
    warehouse_name,
    department,
    total_store_sales,
    total_web_sales,
    store_txn_cnt,
    web_order_cnt,
    high_price_store_sales,
    high_price_web_sales,
    SUM(total_store_sales + total_web_sales) OVER (
        PARTITION BY department
        ORDER BY total_store_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_dept
FROM sales_agg
ORDER BY total_store_sales DESC, total_web_sales DESC
LIMIT 100
