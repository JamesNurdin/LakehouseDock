WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
    WHERE lo_discount > 5
)
SELECT
    c.c_region,
    s.s_region,
    sum(f.lo_revenue) AS total_revenue,
    sum(f.lo_revenue - f.lo_supplycost) AS total_profit,
    avg(f.lo_discount) AS avg_discount,
    count(distinct f.lo_orderkey) AS distinct_orders
FROM filtered_orders f
JOIN customer c ON f.lo_custkey = c.c_custkey
JOIN supplier s ON f.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'BUILDING'
GROUP BY c.c_region, s.s_region
ORDER BY total_profit DESC
LIMIT 10
