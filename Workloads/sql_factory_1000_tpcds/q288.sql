WITH cust_ship AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        w.w_warehouse_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_visited
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, c.c_birth_country, w.w_warehouse_name
    HAVING SUM(cs.cs_net_paid) > 1000
)
SELECT
    cs.c_customer_id,
    cs.c_birth_country,
    cs.w_warehouse_name,
    cs.total_net_paid,
    cs.total_ship_cost,
    cs.total_ship_cost / NULLIF(SUM(cs.total_ship_cost) OVER (), 0) * 100 AS ship_cost_pct_of_total,
    CASE
        WHEN cs.total_ship_cost / NULLIF(cs.total_net_paid, 0) > 0.2 THEN 'HIGH_SHIP_COST_RATIO'
        WHEN cs.total_ship_cost / NULLIF(cs.total_net_paid, 0) BETWEEN 0.1 AND 0.2 THEN 'MEDIUM_SHIP_COST_RATIO'
        ELSE 'LOW_SHIP_COST_RATIO'
    END AS ship_cost_ratio_category,
    cs.web_pages_visited,
    RANK() OVER (ORDER BY cs.total_net_paid DESC) AS customer_sales_rank
FROM cust_ship cs
ORDER BY customer_sales_rank
LIMIT 50
