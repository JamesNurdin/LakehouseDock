SELECT
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE lo.lo_quantity > 30
  AND lo.lo_discount < 10
  AND p.p_size >= 20
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
