WITH order_dates AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_extendedprice,
        lo_quantity,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_shipmode
    FROM lineorder
),
joined AS (
    SELECT
        od.lo_orderkey,
        od.lo_linenumber,
        od.lo_custkey,
        od.lo_partkey,
        od.lo_suppkey,
        od.lo_orderdate,
        od.lo_commitdate,
        od.lo_extendedprice,
        od.lo_quantity,
        od.lo_discount,
        od.lo_revenue,
        od.lo_supplycost,
        od.lo_tax,
        od.lo_shipmode,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation,
        od_date.d_year AS order_year,
        od_date.d_month AS order_month,
        od_date.d_date AS order_date,
        cm_date.d_year AS commit_year
    FROM order_dates od
    JOIN customer c ON od.lo_custkey = c.c_custkey
    JOIN part p ON od.lo_partkey = p.p_partkey
    JOIN supplier s ON od.lo_suppkey = s.s_suppkey
    JOIN dim_date od_date ON CAST(od.lo_orderdate AS varchar) = od_date.d_datekey
    JOIN dim_date cm_date ON CAST(od.lo_commitdate AS varchar) = cm_date.d_datekey
    WHERE od_date.d_year = '1995'
)
SELECT
    cust_region,
    supp_region,
    p_category,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM joined
GROUP BY cust_region, supp_region, p_category, order_year
ORDER BY total_revenue DESC
LIMIT 100
