WITH agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders_cs,
        SUM(cs.cs_ext_sales_price) AS total_sales_cs,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders_ws,
        SUM(ws.ws_ext_sales_price) AS total_sales_ws,
        AVG(cs.cs_quantity) AS avg_qty_cs,
        AVG(ws.ws_quantity) AS avg_qty_ws,
        SUM(CASE WHEN wr.wr_return_tax IS NOT NULL THEN wr.wr_return_tax ELSE 0 END) AS total_return_tax,
        COUNT(DISTINCT ca_bill.ca_state) AS distinct_bill_states
    FROM
        warehouse w
        JOIN catalog_sales cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        sm_cs.sm_code = 'AIR'
        AND w.w_state = 'CA'
        AND td.t_hour BETWEEN 8 AND 12
        AND wp.wp_image_count >= 4
        AND (wr.wr_return_tax IS NULL OR wr.wr_return_tax > 5.00)
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name
)
SELECT
    a.w_warehouse_name,
    a.distinct_orders_cs,
    a.total_sales_cs,
    a.distinct_orders_ws,
    a.total_sales_ws,
    a.total_return_tax,
    a.distinct_bill_states,
    CASE
        WHEN a.total_sales_cs > (SELECT AVG(total_sales_cs) FROM agg) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS sales_category
FROM agg a
WHERE a.total_sales_ws > 10000
ORDER BY a.total_sales_cs DESC
LIMIT 100
