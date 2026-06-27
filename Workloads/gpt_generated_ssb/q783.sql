WITH lo_detail AS (
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
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        c.c_mktsegment AS cust_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        od.d_year AS order_year,
        od.d_month AS order_month,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1995'
)
SELECT
    cust_region,
    cust_nation,
    p_category,
    p_brand1,
    order_year,
    order_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_detail
GROUP BY
    cust_region,
    cust_nation,
    p_category,
    p_brand1,
    order_year,
    order_month
ORDER BY total_revenue DESC
LIMIT 100
