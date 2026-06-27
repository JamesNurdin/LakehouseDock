WITH profit_by_order AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_extendedprice,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
)
SELECT
    c.c_region,
    c.c_nation,
    SUM(p.profit) AS total_profit,
    SUM(p.lo_quantity) AS total_quantity,
    AVG(p.lo_discount) AS avg_discount,
    COUNT(DISTINCT p.lo_orderkey) AS num_orders
FROM profit_by_order p
JOIN customer c
    ON p.lo_custkey = c.c_custkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
GROUP BY c.c_region, c.c_nation
ORDER BY total_profit DESC
LIMIT 5
