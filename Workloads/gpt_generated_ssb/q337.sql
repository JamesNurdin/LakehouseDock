WITH lo_joined AS (
  SELECT
    lo.lo_orderkey,
    lo.lo_linenumber,
    lo.lo_custkey,
    lo.lo_partkey,
    lo.lo_suppkey,
    lo.lo_orderdate,
    lo.lo_commitdate,
    lo.lo_quantity,
    lo.lo_extendedprice,
    lo.lo_ordertotalprice,
    lo.lo_discount,
    lo.lo_revenue,
    lo.lo_supplycost,
    lo.lo_tax,
    od.d_year AS order_year,
    od.d_month AS order_month,
    cd.d_year AS commit_year,
    p.p_category,
    p.p_brand1,
    s.s_region AS supplier_region,
    c.c_region AS customer_region,
    c.c_mktsegment
  FROM lineorder lo
  JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
  JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  JOIN customer c ON lo.lo_custkey = c.c_custkey
  WHERE od.d_year = '1995'
    AND p.p_category = 'MFGR#12'
    AND s.s_region = 'ASIA'
),
aggregated AS (
  SELECT
    order_year,
    supplier_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_count
  FROM lo_joined
  GROUP BY order_year, supplier_region
)
SELECT
  order_year,
  supplier_region,
  total_revenue,
  total_profit,
  avg_discount,
  order_count,
  RANK() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 10
