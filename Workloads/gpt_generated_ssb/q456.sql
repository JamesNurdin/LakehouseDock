WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_suppkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_orderdate
    FROM lineorder
    WHERE lo_quantity > 0
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    c.c_mktsegment AS market_segment,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_supplycost) AS total_supply_cost,
    SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
    SUM(f.lo_quantity) AS total_quantity,
    AVG(f.lo_discount) AS avg_discount,
    COUNT(DISTINCT f.lo_orderkey) AS distinct_orders
FROM filtered_orders f
JOIN customer c ON f.lo_custkey = c.c_custkey
JOIN supplier s ON f.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
GROUP BY c.c_region, s.s_region, c.c_mktsegment
HAVING SUM(f.lo_revenue) > 1000000
ORDER BY total_profit DESC
LIMIT 10
