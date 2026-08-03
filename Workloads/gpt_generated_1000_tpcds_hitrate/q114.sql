/*
Goal: Identify top customers by total catalog sales, enriched with web sales performance and return statistics, while filtering on specific departments, warehouse street type, web page flags, and month. The query excludes orders that have large returns (anti‑semi‑join), classifies customers by sales volume using a CASE expression, and ranks customers per their total sales.
*/
WITH aggregated AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cp.cp_department,
        w.w_state,
        SUM(cs.cs_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(cr.cr_return_amount) AS min_return,
        MAX(cr.cr_return_amount) AS max_return,
        SUM(cs.cs_quantity) AS total_quantity
    FROM
        catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                     AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d_sold.d_moy = 9
        AND w.w_street_type = 'Avenue'
        AND cp.cp_department = 'Electronics'
        AND wp.wp_autogen_flag = 'N'
        AND cs.cs_order_number NOT IN (
            SELECT cr2.cr_order_number
            FROM catalog_returns cr2
            WHERE cr2.cr_return_amount > 1000
        )
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        cp.cp_department,
        w.w_state
)
SELECT
    c_customer_id,
    cp_department,
    w_state,
    total_sales,
    avg_web_sales,
    distinct_orders,
    min_return,
    max_return,
    CASE WHEN total_quantity > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
    ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
