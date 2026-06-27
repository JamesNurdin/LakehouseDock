SELECT
    d.d_year AS order_year,
    s.s_nation AS supplier_nation,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
WHERE d.d_year = '1995'
  AND p.p_category = 'MFGR#1'
GROUP BY d.d_year, s.s_nation, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
