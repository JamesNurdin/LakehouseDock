SELECT
    c.c_region,
    c.c_nation,
    c.c_mktsegment,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE c.c_region = 'AMERICA'
GROUP BY
    c.c_region,
    c.c_nation,
    c.c_mktsegment,
    p.p_category
ORDER BY total_profit DESC
LIMIT 100
