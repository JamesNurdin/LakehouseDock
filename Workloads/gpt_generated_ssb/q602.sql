/*
  Analytical query: total revenue, supply cost, and profit by order year, customer region, and supplier region
  for orders placed in 1995 that involve parts in category 'MFGR#1'.
*/
WITH order_dim AS (
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
        lo.lo_shipmode,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        p.p_mfgr,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#1'
)
SELECT
    order_year,
    cust_region,
    supp_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_dim
GROUP BY order_year, cust_region, supp_region, p_category
ORDER BY total_profit DESC
LIMIT 10
