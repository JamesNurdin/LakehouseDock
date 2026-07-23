WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_carrier AS carrier,
        r.r_reason_desc AS return_reason,
        d.d_year AS year,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM catalog_sales cs
    INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d.d_date_sk
    INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Electronics'
      AND sm.sm_carrier = 'UPS'
      AND w.w_state = 'CA'
      AND r.r_reason_desc = 'Damaged'
      AND inv.inv_quantity_on_hand > 500
    GROUP BY cp.cp_department, sm.sm_carrier, r.r_reason_desc, d.d_year
),
dept_avg AS (
    SELECT
        department,
        AVG(total_profit) AS avg_profit,
        SUM(distinct_customers) AS total_customers
    FROM sales_agg
    GROUP BY department
)
SELECT
    s.department,
    s.carrier,
    s.year,
    s.distinct_customers,
    s.total_profit,
    s.total_sales,
    s.total_return_amount,
    s.total_web_profit,
    d.avg_profit,
    s.total_profit / NULLIF(s.distinct_customers, 0) AS profit_per_customer
FROM sales_agg s
INNER JOIN dept_avg d ON s.department = d.department
WHERE s.total_sales > 100000
ORDER BY s.total_profit DESC
LIMIT 100
