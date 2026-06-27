WITH order_date AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    od.d_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_cnt
FROM order_date od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#1'
  AND s.s_region = 'ASIA'
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
