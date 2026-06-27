WITH revenue_per_supplier AS (
    SELECT
        c.c_region,
        s.s_name,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
    GROUP BY c.c_region, s.s_name
)
SELECT
    r.c_region,
    r.s_name,
    r.total_revenue,
    r.avg_discount,
    RANK() OVER (PARTITION BY r.c_region ORDER BY r.total_revenue DESC) AS revenue_rank
FROM revenue_per_supplier r
ORDER BY r.c_region, revenue_rank
LIMIT 20
