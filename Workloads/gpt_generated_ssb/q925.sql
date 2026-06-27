WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region,
    od.d_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dates od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12'
GROUP BY c.c_region, od.d_year
HAVING SUM(od.lo_revenue) > 1000000
ORDER BY total_revenue DESC
