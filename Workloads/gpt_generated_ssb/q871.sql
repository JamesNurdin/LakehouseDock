WITH order_dates AS (
    SELECT d_datekey, d_year, d_date
    FROM dim_date
    WHERE CAST(d_date AS date) >= DATE '1995-01-01'
      AND CAST(d_date AS date) < DATE '1996-01-01'
)
SELECT
    c.c_region,
    od.d_year,
    p.p_brand1,
    s.s_nation,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN order_dates od
  ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    od.d_year,
    p.p_brand1,
    s.s_nation
ORDER BY total_revenue DESC
LIMIT 10
