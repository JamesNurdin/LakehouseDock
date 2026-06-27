WITH cust_revenue AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        SUM(lo.lo_revenue) AS revenue,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_quantity > 30
    GROUP BY c.c_custkey, c.c_name, c.c_region
),
ranked_customers AS (
    SELECT
        c_custkey,
        c_name,
        c_region,
        revenue,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY revenue DESC) AS region_rank
    FROM cust_revenue
)
SELECT
    c_custkey,
    c_name,
    c_region,
    revenue,
    order_cnt,
    region_rank
FROM ranked_customers
WHERE region_rank <= 5
ORDER BY c_region, revenue DESC
