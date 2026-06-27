SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
FROM lineorder lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN part p ON lo.lo_partkey = p.p_partkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
GROUP BY c.c_region, s.s_region, p.p_category
HAVING SUM(lo.lo_revenue) > 500000
ORDER BY total_revenue DESC
LIMIT 10
