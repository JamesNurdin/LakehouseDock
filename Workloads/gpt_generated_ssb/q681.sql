WITH lo_filtered AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_commitdate,
        lo_shipmode
    FROM lineorder
)
SELECT
    s.s_region      AS supplier_region,
    p.p_category    AS part_category,
    c.c_mktsegment  AS customer_segment,
    SUM(lo.lo_revenue)                         AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost)      AS total_profit
FROM lo_filtered lo
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN part     p ON lo.lo_partkey = p.p_partkey
JOIN customer c ON lo.lo_custkey = c.c_custkey
WHERE s.s_region = 'ASIA'
  AND p.p_category = 'MFGR#1'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY s.s_region, p.p_category, c.c_mktsegment
ORDER BY total_revenue DESC
