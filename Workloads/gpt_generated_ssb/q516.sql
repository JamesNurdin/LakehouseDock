SELECT
    od.d_year AS order_year,
    cust.c_region,
    supp.s_region,
    part.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd
  ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
JOIN customer cust
  ON lo.lo_custkey = cust.c_custkey
JOIN part part
  ON lo.lo_partkey = part.p_partkey
JOIN supplier supp
  ON lo.lo_suppkey = supp.s_suppkey
WHERE CAST(cd.d_date AS DATE) >= DATE '1995-01-01'
GROUP BY od.d_year, cust.c_region, supp.s_region, part.p_category
HAVING SUM(lo.lo_revenue) > 1000000
ORDER BY od.d_year, cust.c_region, supp.s_region, part.p_category
