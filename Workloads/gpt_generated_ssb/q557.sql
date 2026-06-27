SELECT
    s.s_region AS supplier_region,
    c.c_region AS customer_region,
    d.d_year AS order_year,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_sales,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date d
  ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
  AND d.d_year = '1995'
  AND lo.lo_shipmode = 'AIR'
GROUP BY s.s_region, c.c_region, d.d_year
ORDER BY total_profit DESC
LIMIT 20
