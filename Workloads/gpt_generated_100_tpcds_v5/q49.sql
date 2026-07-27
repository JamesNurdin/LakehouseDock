/* goal: Analyze sales performance by warehouse, department and hour of day, comparing two different sales segments with distinct filters, and compute running totals and ranking per warehouse */
WITH sales_by_warehouse AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        cp.cp_department AS department,
        td.t_hour AS hour,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        AVG(cs.cs_quantity) AS avg_qty,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MIN(cs.cs_net_paid_inc_ship) AS min_sale,
        MAX(cs.cs_net_paid_inc_ship) AS max_sale
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
      AND td.t_hour BETWEEN 9 AND 12
      AND c_bill.c_first_name = 'Joseph'
    GROUP BY w.w_warehouse_name, cp.cp_department, td.t_hour
),
sales_by_item AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        cp.cp_department AS department,
        td.t_hour AS hour,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        AVG(cs.cs_quantity) AS avg_qty,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MIN(cs.cs_net_paid_inc_ship) AS min_sale,
        MAX(cs.cs_net_paid_inc_ship) AS max_sale
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_paid_inc_ship BETWEEN 500 AND 1500
      AND td.t_hour BETWEEN 13 AND 17
      AND c_ship.c_first_name = 'Iesha'
    GROUP BY w.w_warehouse_name, cp.cp_department, td.t_hour
)
SELECT
    warehouse_name,
    department,
    hour,
    total_sales,
    avg_qty,
    order_cnt,
    min_sale,
    max_sale,
    SUM(total_sales) OVER (PARTITION BY warehouse_name ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    RANK() OVER (PARTITION BY warehouse_name ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT warehouse_name, department, hour, total_sales, avg_qty, order_cnt, min_sale, max_sale FROM sales_by_warehouse
    UNION ALL
    SELECT warehouse_name, department, hour, total_sales, avg_qty, order_cnt, min_sale, max_sale FROM sales_by_item
) combined
ORDER BY warehouse_name, total_sales DESC
LIMIT 100
