/*
  Revenue, profit and discount analysis by order year and customer nation.
  Filters:
    • Part category = 'MFGR#12'
    • Supplier region = 'ASIA'
    • Order year between 1992 and 1997 (inclusive)
    • Commit year >= 1992
*/
WITH order_base AS (
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
        c.c_nation,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
      AND od.d_year BETWEEN '1992' AND '1997'
      AND cd.d_year >= '1992'
)
SELECT
    order_year,
    c_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_base
GROUP BY order_year, c_nation
ORDER BY total_revenue DESC
LIMIT 10
