SELECT
    d.d_year AS year,
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
WHERE d.d_date >= '1997-01-01'
  AND d.d_date <= '1997-12-31'
GROUP BY
    d.d_year,
    c.c_region,
    s.s_region,
    p.p_category
ORDER BY total_revenue DESC
