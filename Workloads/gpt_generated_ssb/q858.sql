WITH filtered_lo AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
    WHERE lo_discount >= 0 AND lo_discount <= 5
)
SELECT
    c.c_region,
    s.s_nation,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
    SUM(lo.lo_revenue) / NULLIF(COUNT(DISTINCT lo.lo_orderkey), 0) AS avg_revenue_per_order
FROM filtered_lo lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category = 'MFGR#1'
  AND s.s_region = 'ASIA'
GROUP BY c.c_region, s.s_nation, p.p_category
ORDER BY total_revenue DESC
LIMIT 50
