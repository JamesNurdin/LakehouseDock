WITH order_details AS (
  SELECT
    lo.lo_orderkey,
    lo.lo_custkey,
    lo.lo_partkey,
    lo.lo_suppkey,
    lo.lo_orderdate,
    lo.lo_commitdate,
    lo.lo_revenue,
    lo.lo_supplycost,
    lo.lo_discount,
    lo.lo_quantity,
    lo.lo_extendedprice,
    lo.lo_tax,
    lo.lo_shipmode,
    od.d_year AS order_year,
    cd.d_year AS commit_year,
    date(od.d_date) AS order_date,
    date(cd.d_date) AS commit_date,
    c.c_region,
    p.p_category,
    s.s_region AS supplier_region
  FROM lineorder lo
  JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
  JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
  JOIN customer c ON lo.lo_custkey = c.c_custkey
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  WHERE od.d_year = '1995'
)
SELECT
  order_details.c_region,
  order_details.p_category,
  COUNT(*) AS order_cnt,
  SUM(order_details.lo_revenue) AS total_revenue,
  SUM(order_details.lo_supplycost) AS total_supplycost,
  SUM(order_details.lo_revenue) - SUM(order_details.lo_supplycost) AS profit,
  AVG(order_details.lo_discount) AS avg_discount,
  AVG(date_diff('day', order_details.order_date, order_details.commit_date)) AS avg_lead_days
FROM order_details
GROUP BY order_details.c_region, order_details.p_category
ORDER BY profit DESC
LIMIT 10
