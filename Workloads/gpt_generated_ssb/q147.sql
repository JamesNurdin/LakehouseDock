WITH order_dates AS (
  SELECT
    lo.lo_orderkey,
    lo.lo_linenumber,
    lo.lo_custkey,
    lo.lo_partkey,
    lo.lo_suppkey,
    lo.lo_quantity,
    lo.lo_extendedprice,
    lo.lo_ordertotalprice,
    lo.lo_discount,
    lo.lo_revenue,
    lo.lo_supplycost,
    lo.lo_tax,
    lo.lo_shipmode,
    d_order.d_date AS order_date,
    d_order.d_year AS order_year,
    d_commit.d_date AS commit_date
  FROM lineorder lo
  JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
  JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
  c.c_region,
  od.order_year,
  p.p_category,
  s.s_region AS supplier_region,
  SUM(od.lo_revenue) AS total_revenue,
  SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
  AVG(od.lo_discount) AS avg_discount,
  COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
WHERE CAST(od.order_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
  AND CAST(od.commit_date AS date) >= DATE '1995-06-01'
GROUP BY c.c_region, od.order_year, p.p_category, s.s_region
HAVING SUM(od.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100
