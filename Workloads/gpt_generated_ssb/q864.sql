WITH lo_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        s.s_region AS supplier_region,
        s.s_nation AS supplier_nation,
        (lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS profit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'ASIA'
      AND s.s_region = 'EUROPE'
      AND lo.lo_discount > 0
      AND lo.lo_quantity >= 5
)
SELECT
    c_region,
    supplier_region,
    c_mktsegment,
    SUM(lo_revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_custkey) AS distinct_customers
FROM lo_enriched
GROUP BY
    c_region,
    supplier_region,
    c_mktsegment
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
