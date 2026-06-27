WITH revenue_calc AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS revenue,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost AS profit
    FROM lineorder lo
)
SELECT
    s.s_region AS supplier_region,
    d.d_year AS order_year,
    SUM(rc.revenue) AS total_revenue,
    SUM(rc.profit) AS total_profit,
    COUNT(DISTINCT rc.lo_orderkey) AS order_count
FROM revenue_calc rc
JOIN supplier s
  ON rc.lo_suppkey = s.s_suppkey
JOIN dim_date d
  ON CAST(rc.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN part p
  ON rc.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
  AND p.p_category = 'MFGR#12'
GROUP BY s.s_region, d.d_year
ORDER BY total_revenue DESC
