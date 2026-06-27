WITH order_dim AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
      ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
)
SELECT
    c.c_region,
    od.d_year,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS profit
FROM order_dim od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    od.d_year,
    p.p_category
ORDER BY profit DESC
LIMIT 20
