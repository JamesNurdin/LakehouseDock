WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year AS order_year,
        d.d_date AS order_date,
        dc.d_year AS commit_year,
        dc.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date dc
      ON CAST(dc.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    s.s_region AS supplier_region,
    c.c_region AS customer_region,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dim od
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
JOIN customer c
  ON od.lo_custkey = c.c_custkey
WHERE
    p.p_category = 'MFGR#1'
    AND CAST(od.order_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY
    s.s_region,
    c.c_region,
    od.order_year
ORDER BY
    total_revenue DESC
LIMIT 20
