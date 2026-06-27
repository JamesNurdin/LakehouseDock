SELECT
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders,
    COUNT(*) AS line_items
FROM lineorder lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
WHERE c.c_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
GROUP BY c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
