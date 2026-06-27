SELECT
    s.s_region,
    od.d_year AS order_year,
    p.p_category,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_sales,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd
  ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN customer cu
  ON lo.lo_custkey = cu.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE
    od.d_year = '1995'
    AND p.p_category = 'MFGR#1'
    AND s.s_region = 'ASIA'
    AND lo.lo_shipmode = 'AIR'
    AND CAST(cd.d_year AS integer) >= CAST(od.d_year AS integer)
GROUP BY
    s.s_region,
    od.d_year,
    p.p_category
ORDER BY
    total_profit DESC
LIMIT 10
