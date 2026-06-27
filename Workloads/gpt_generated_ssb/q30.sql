WITH line_revenue AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderkey,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS revenue,
        lo.lo_supplycost * lo.lo_quantity AS supply_cost,
        lo.lo_discount
    FROM lineorder lo
)
SELECT
    s.s_region,
    p.p_brand1,
    SUM(lr.revenue) AS total_revenue,
    SUM(lr.revenue - lr.supply_cost) AS total_profit,
    AVG(lr.lo_discount) AS avg_discount,
    COUNT(DISTINCT lr.lo_orderkey) AS order_count
FROM line_revenue lr
JOIN customer c ON lr.lo_custkey = c.c_custkey
JOIN part p ON lr.lo_partkey = p.p_partkey
JOIN supplier s ON lr.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND s.s_region = 'ASIA'
  AND p.p_category = 'MFGR#1'
GROUP BY s.s_region, p.p_brand1
ORDER BY total_revenue DESC
LIMIT 10
