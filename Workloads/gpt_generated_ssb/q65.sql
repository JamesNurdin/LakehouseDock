/*
  Revenue, profit and order count by order year, customer region and part category
  for orders committed in 1995 and belonging to a specific part category.
*/
WITH lo_cast AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_supplycost,
        lo.lo_tax,
        CAST(lo.lo_orderdate AS VARCHAR) AS order_date_key,
        CAST(lo.lo_commitdate AS VARCHAR) AS commit_date_key
    FROM lineorder lo
)
SELECT
    d_order.d_year                     AS order_year,
    c.c_region                         AS customer_region,
    p.p_category                       AS part_category,
    SUM(lo_cast.lo_extendedprice * (100 - lo_cast.lo_discount) / 100.0) AS revenue,
    SUM((lo_cast.lo_extendedprice * (100 - lo_cast.lo_discount) / 100.0) - lo_cast.lo_supplycost) AS profit,
    COUNT(DISTINCT lo_cast.lo_orderkey) AS num_orders
FROM lo_cast
JOIN dim_date d_order   ON lo_cast.order_date_key = d_order.d_datekey
JOIN dim_date d_commit  ON lo_cast.commit_date_key = d_commit.d_datekey
JOIN customer c         ON lo_cast.lo_custkey = c.c_custkey
JOIN part p             ON lo_cast.lo_partkey = p.p_partkey
JOIN supplier s         ON lo_cast.lo_suppkey = s.s_suppkey
WHERE d_commit.d_year = '1995'
  AND p.p_category = 'MFGR#1'
GROUP BY d_order.d_year, c.c_region, p.p_category
ORDER BY revenue DESC
LIMIT 10
