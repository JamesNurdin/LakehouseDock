WITH order_agg AS (
  SELECT
    od.d_year AS order_year,
    c.c_region,
    p.p_category,
    p.p_brand1,
    s.s_nation AS supplier_nation,
    SUM(lo.lo_extendedprice) AS total_extendedprice,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_quantity) AS total_quantity
  FROM lineorder lo
  JOIN customer c ON lo.lo_custkey = c.c_custkey
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
  WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
  GROUP BY od.d_year, c.c_region, p.p_category, p.p_brand1, s.s_nation
)
SELECT
  order_year,
  c_region,
  p_category,
  p_brand1,
  supplier_nation,
  total_extendedprice,
  total_revenue,
  total_supplycost,
  total_profit,
  avg_discount,
  total_quantity,
  RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM order_agg
ORDER BY total_revenue DESC
LIMIT 100
