WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_partkey,
        lo_suppkey,
        lo_quantity,
        lo_extendedprice,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
    WHERE lo_quantity > 30
      AND lo_discount BETWEEN 5 AND 10
)
SELECT
    s.s_region,
    p.p_category,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_supplycost) AS total_supplycost,
    SUM(f.lo_revenue) - SUM(f.lo_supplycost) AS total_profit,
    COUNT(DISTINCT f.lo_orderkey) AS order_cnt,
    AVG(f.lo_discount) AS avg_discount
FROM filtered_orders f
JOIN part p ON f.lo_partkey = p.p_partkey
JOIN supplier s ON f.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
HAVING SUM(f.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100
