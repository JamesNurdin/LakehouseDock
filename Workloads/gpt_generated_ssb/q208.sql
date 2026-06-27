WITH line_profit AS (
    SELECT 
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
)
SELECT 
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    SUM(lp.lo_revenue) AS total_revenue,
    SUM(lp.profit) AS total_profit,
    COUNT(*) AS line_count
FROM line_profit lp
JOIN customer c
    ON lp.lo_custkey = c.c_custkey
JOIN supplier s
    ON lp.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
GROUP BY c.c_region, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
