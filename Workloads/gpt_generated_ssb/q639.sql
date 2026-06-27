WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        od.d_year AS order_year,
        od.d_month AS order_month,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    WHERE od.d_year BETWEEN '1992' AND '1997'
)
SELECT
    cust_region,
    supp_region,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_joined
GROUP BY cust_region, supp_region, order_year
ORDER BY total_revenue DESC
LIMIT 100
