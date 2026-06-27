WITH region_segment AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT c.c_custkey) AS num_customers
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    GROUP BY c.c_region, c.c_mktsegment
)
SELECT
    rs.c_region,
    rs.c_mktsegment,
    rs.total_revenue,
    rs.total_quantity,
    rs.avg_discount,
    rs.num_customers,
    RANK() OVER (ORDER BY rs.total_revenue DESC) AS revenue_rank
FROM region_segment rs
ORDER BY rs.total_revenue DESC
