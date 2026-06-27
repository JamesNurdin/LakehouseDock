SELECT
    od.d_year AS order_year,
    od.d_month AS order_month,
    p.p_category AS product_category,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_quantity) AS total_quantity
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd
  ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-12-01' AND DATE '1995-12-31'
  AND cd.d_holidayfl = 'N'
GROUP BY
    od.d_year,
    od.d_month,
    p.p_category,
    s.s_region
ORDER BY total_revenue DESC
LIMIT 10
