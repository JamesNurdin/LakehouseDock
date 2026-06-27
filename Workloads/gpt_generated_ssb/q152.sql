WITH revenue_by_customer AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_nation,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    GROUP BY
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_nation
),
ranked_customers AS (
    SELECT
        rbc.c_custkey,
        rbc.c_name,
        rbc.c_region,
        rbc.c_nation,
        rbc.total_revenue,
        rbc.total_profit,
        rbc.order_count,
        ROW_NUMBER() OVER (PARTITION BY rbc.c_region ORDER BY rbc.total_revenue DESC) AS region_rank
    FROM revenue_by_customer rbc
)
SELECT
    rc.c_region,
    rc.c_nation,
    rc.c_custkey,
    rc.c_name,
    rc.total_revenue,
    rc.total_profit,
    rc.order_count
FROM ranked_customers rc
WHERE rc.region_rank <= 3
ORDER BY rc.c_region, rc.total_revenue DESC
