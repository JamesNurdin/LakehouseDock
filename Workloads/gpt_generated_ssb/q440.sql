WITH regional_sales AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        lo.lo_shipmode,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region IS NOT NULL
    GROUP BY c.c_region, c.c_mktsegment, lo.lo_shipmode
)
SELECT
    rs.c_region,
    rs.c_mktsegment,
    rs.lo_shipmode,
    rs.total_revenue,
    rs.avg_discount,
    rs.order_count,
    rs.revenue_rank
FROM (
    SELECT
        regional_sales.c_region,
        regional_sales.c_mktsegment,
        regional_sales.lo_shipmode,
        regional_sales.total_revenue,
        regional_sales.avg_discount,
        regional_sales.order_count,
        RANK() OVER (
            PARTITION BY regional_sales.c_region, regional_sales.c_mktsegment
            ORDER BY regional_sales.total_revenue DESC
        ) AS revenue_rank
    FROM regional_sales
) rs
WHERE rs.revenue_rank <= 3
ORDER BY rs.c_region, rs.c_mktsegment, rs.revenue_rank
