WITH revenue_by_customer AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_shipmode = 'AIR'
    GROUP BY c.c_region, c.c_mktsegment
)
SELECT
    r.c_region,
    r.c_mktsegment,
    r.total_revenue,
    r.total_quantity,
    r.num_orders,
    r.avg_discount,
    RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
FROM revenue_by_customer r
ORDER BY r.total_revenue DESC
