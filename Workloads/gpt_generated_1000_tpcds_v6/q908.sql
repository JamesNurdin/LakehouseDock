WITH agg AS (
    SELECT
        cp.cp_department,
        sm.sm_type,
        ca.ca_location_type,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_sales_price) AS avg_ext_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    WHERE cp.cp_catalog_number IN (5, 8)
      AND ca.ca_location_type = 'single family'
      AND cs.cs_ext_list_price > 1000
    GROUP BY cp.cp_department, sm.sm_type, ca.ca_location_type
)
SELECT
    cp_department,
    sm_type,
    ca_location_type,
    total_profit,
    avg_ext_sales,
    order_cnt,
    CASE WHEN total_quantity > 100 THEN 'HIGH' ELSE 'LOW' END AS quantity_level,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS dept_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
