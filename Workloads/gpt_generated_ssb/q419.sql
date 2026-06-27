WITH revenue_by_region_nation AS (
    SELECT
        c.c_region,
        s.s_nation,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderdate BETWEEN 19920101 AND 19921231
    GROUP BY c.c_region, s.s_nation
)
SELECT
    c_region,
    s_nation,
    total_revenue,
    total_supplycost,
    total_revenue - total_supplycost AS profit,
    order_cnt,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_nation
ORDER BY revenue_rank
LIMIT 10
