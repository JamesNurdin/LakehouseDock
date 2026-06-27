WITH order_join AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        dd_order.d_year AS order_year,
        dd_order.d_month AS order_month,
        dd_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date dd_order
        ON CAST(dd_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date dd_commit
        ON CAST(dd_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    cust_region,
    supp_region,
    p_category,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(*) AS total_lineitems
FROM order_join
WHERE p_category = 'MFGR#12'
  AND order_year = '1995'
  AND commit_year = '1995'
GROUP BY cust_region, supp_region, p_category, order_year
ORDER BY total_revenue DESC
LIMIT 10
