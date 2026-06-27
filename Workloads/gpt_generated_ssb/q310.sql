SELECT
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_revenue - lo.lo_supplycost) / SUM(lo.lo_revenue) AS profit_margin,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date d
  ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
  AND lo.lo_discount < 5
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
