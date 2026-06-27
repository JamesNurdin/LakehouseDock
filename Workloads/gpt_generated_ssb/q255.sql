WITH line_net AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_extendedprice,
        lo_discount,
        lo_extendedprice * (100 - lo_discount) / 100 AS net_price,
        lo_revenue,
        lo_supplycost,
        lo_quantity,
        lo_shipmode,
        lo_orderpriority
    FROM lineorder
)
SELECT
    c.c_region,
    c.c_mktsegment,
    ln.lo_shipmode,
    COUNT(DISTINCT ln.lo_orderkey) AS order_count,
    SUM(ln.net_price) AS total_net_price,
    SUM(ln.lo_revenue) AS total_revenue,
    SUM(ln.lo_revenue - ln.lo_supplycost) AS total_profit,
    AVG(ln.lo_discount) AS avg_discount,
    SUM(ln.lo_quantity) AS total_quantity
FROM line_net ln
JOIN customer c
    ON ln.lo_custkey = c.c_custkey
WHERE c.c_region IN ('ASIA', 'EUROPE')
  AND ln.lo_shipmode IN ('AIR', 'RAIL')
GROUP BY c.c_region, c.c_mktsegment, ln.lo_shipmode
HAVING SUM(ln.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 20
