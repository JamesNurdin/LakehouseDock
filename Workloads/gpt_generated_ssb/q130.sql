WITH regional_sales AS (
  SELECT
    c.c_region,
    d.d_year,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost) AS profit,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
  FROM lineorder lo
  JOIN customer c ON lo.lo_custkey = c.c_custkey
  JOIN dim_date d ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  WHERE p.p_category = 'MFGR#12'
    AND d.d_year = '1995'
  GROUP BY c.c_region, d.d_year
)
SELECT
  c_region,
  d_year,
  revenue,
  profit,
  num_orders,
  profit / revenue AS profit_margin,
  revenue / SUM(revenue) OVER () * 100 AS revenue_pct_of_total
FROM regional_sales
ORDER BY profit DESC
LIMIT 5
