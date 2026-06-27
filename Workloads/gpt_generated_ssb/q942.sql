WITH order_details AS (
  SELECT
    lo.lo_orderkey,
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
    c.c_region,
    c.c_nation,
    p.p_category,
    p.p_brand1,
    s.s_region,
    od.d_year AS order_year,
    CAST(od.d_daynuminyear AS INTEGER) AS order_daynum,
    CAST(cd.d_daynuminyear AS INTEGER) AS commit_daynum,
    (CAST(cd.d_daynuminyear AS INTEGER) - CAST(od.d_daynuminyear AS INTEGER)) AS lead_time_days,
    (lo.lo_revenue - lo.lo_supplycost) AS profit
  FROM lineorder lo
  JOIN customer c ON lo.lo_custkey = c.c_custkey
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
  JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
  WHERE od.d_year = '1995'
),
agg AS (
  SELECT
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(lead_time_days) AS avg_lead_time,
    COUNT(DISTINCT lo_orderkey) AS num_orders
  FROM order_details
  GROUP BY c_region, p_category
)
SELECT
  c_region,
  p_category,
  total_revenue,
  total_profit,
  avg_discount,
  avg_lead_time,
  num_orders,
  RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 20
