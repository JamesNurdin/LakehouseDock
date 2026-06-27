WITH revenue_by_supplier AS (
    SELECT
        c.c_mktsegment,
        s.s_name,
        SUM(lo.lo_revenue) AS segment_supplier_revenue,
        SUM(lo.lo_extendedprice - lo.lo_supplycost) AS segment_supplier_profit,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'EUROPE'
    GROUP BY c.c_mktsegment, s.s_name
    HAVING COUNT(*) > 10
)
SELECT
    c_mktsegment,
    s_name,
    segment_supplier_revenue,
    segment_supplier_profit,
    order_count,
    RANK() OVER (PARTITION BY c_mktsegment ORDER BY segment_supplier_revenue DESC) AS revenue_rank
FROM revenue_by_supplier
ORDER BY c_mktsegment, revenue_rank
LIMIT 20
