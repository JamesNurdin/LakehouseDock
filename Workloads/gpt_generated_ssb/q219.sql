SELECT
    od.d_year AS order_year,
    s.s_region AS supplier_region,
    p.p_category AS product_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    (SUM(lo.lo_revenue) - SUM(lo.lo_supplycost)) / SUM(lo.lo_revenue) AS profit_margin
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(od.d_date AS DATE) >= DATE '1995-01-01'
  AND CAST(od.d_date AS DATE) < DATE '1996-01-01'
GROUP BY od.d_year, s.s_region, p.p_category
HAVING (SUM(lo.lo_revenue) - SUM(lo.lo_supplycost)) / SUM(lo.lo_revenue) > 0.1
ORDER BY total_revenue DESC
