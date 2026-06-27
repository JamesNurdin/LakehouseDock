WITH order_data AS (
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
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        p.p_category,
        p.p_brand1,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    WHERE od.d_year BETWEEN '1995' AND '1997'
)
SELECT
    order_year,
    cust_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_data
GROUP BY order_year, cust_region, p_category
ORDER BY order_year, cust_region, p_category
