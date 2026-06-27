WITH base AS (
  SELECT
    lo.lo_orderkey,
    lo.lo_custkey,
    lo.lo_partkey,
    lo.lo_suppkey,
    lo.lo_orderdate,
    lo.lo_revenue,
    lo.lo_supplycost,
    od.d_year AS order_year,
    c.c_region,
    p.p_category,
    s.s_nation
  FROM lineorder lo
  JOIN dim_date od
    ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
  JOIN customer c
    ON lo.lo_custkey = c.c_custkey
  JOIN part p
    ON lo.lo_partkey = p.p_partkey
  JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
  WHERE od.d_year BETWEEN '1995' AND '1997'
),
aggregated AS (
  SELECT
    order_year,
    c_region,
    p_category,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
  FROM base
  GROUP BY
    order_year,
    c_region,
    p_category,
    s_nation
  HAVING SUM(lo_revenue) > 0
)
SELECT
  order_year,
  c_region,
  p_category,
  s_nation,
  total_revenue,
  total_profit,
  distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY order_year, c_region ORDER BY total_revenue DESC) AS category_rank
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 20
