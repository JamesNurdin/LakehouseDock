SELECT
    p.p_category,
    p.p_brand1,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost * lo.lo_quantity) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE p.p_size >= 10
GROUP BY p.p_category, p.p_brand1
ORDER BY total_revenue DESC
