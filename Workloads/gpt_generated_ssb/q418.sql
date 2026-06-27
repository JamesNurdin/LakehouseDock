WITH lo_agg AS (
    SELECT
        lo_custkey,
        lo_suppkey,
        SUM(lo_extendedprice) AS total_extendedprice,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_count
    FROM lineorder
    WHERE lo_shippriority >= 1
    GROUP BY lo_custkey, lo_suppkey
)
SELECT
    c.c_region AS customer_region,
    c.c_nation AS customer_nation,
    s.s_region AS supplier_region,
    s.s_nation AS supplier_nation,
    lo_agg.total_extendedprice,
    lo_agg.total_revenue,
    lo_agg.total_supplycost,
    lo_agg.total_revenue - lo_agg.total_supplycost AS total_profit,
    lo_agg.total_quantity,
    lo_agg.avg_discount,
    lo_agg.order_count
FROM lo_agg
JOIN customer c ON lo_agg.lo_custkey = c.c_custkey
JOIN supplier s ON lo_agg.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
ORDER BY lo_agg.total_revenue DESC
LIMIT 100
