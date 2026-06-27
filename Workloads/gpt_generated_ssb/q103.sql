WITH lo_profit AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        -- profit = revenue - supply cost
        (lo.lo_extendedprice * (100 - lo.lo_discount) / 100 - lo.lo_supplycost) AS profit
    FROM lineorder lo
)
SELECT
    c.c_region,
    p.p_category,
    SUM(lp.lo_revenue) AS total_revenue,
    SUM(lp.profit) AS total_profit,
    COUNT(*) AS order_count
FROM lo_profit lp
JOIN customer c ON lp.lo_custkey = c.c_custkey
JOIN part p ON lp.lo_partkey = p.p_partkey
JOIN supplier s ON lp.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND s.s_region = 'ASIA'
GROUP BY c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
