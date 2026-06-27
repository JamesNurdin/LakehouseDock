SELECT
    od.d_year AS order_year,
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date od
  ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN dim_date cd
  ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE od.d_year = '1997'
  AND cd.d_year = '1997'
GROUP BY od.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
