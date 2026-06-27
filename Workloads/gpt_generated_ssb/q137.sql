WITH net_lineorder AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_orderpriority,
        (lo.lo_revenue * (1 - lo.lo_discount / 100.0) * (1 + lo.lo_tax / 100.0)) AS net_revenue
    FROM lineorder lo
    WHERE lo.lo_orderdate BETWEEN 19940101 AND 19941231
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    SUM(nl.net_revenue) AS total_net_revenue,
    COUNT(DISTINCT nl.lo_orderkey) AS distinct_orders,
    AVG(nl.lo_discount) AS avg_discount
FROM net_lineorder nl
JOIN customer c ON nl.lo_custkey = c.c_custkey
JOIN supplier s ON nl.lo_suppkey = s.s_suppkey
WHERE nl.lo_orderpriority = '1-URGENT'
GROUP BY c.c_region, s.s_region
ORDER BY total_net_revenue DESC
LIMIT 10
