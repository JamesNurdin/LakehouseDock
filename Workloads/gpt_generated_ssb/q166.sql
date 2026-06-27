WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        c.c_region AS cust_region,
        lo.lo_suppkey,
        s.s_region AS supp_region,
        lo.lo_partkey,
        p.p_category,
        lo.lo_orderdate,
        od.d_year,
        od.d_date AS order_date,
        lo.lo_commitdate,
        cd.d_date AS commit_date,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_shipmode,
        lo.lo_orderpriority
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND lo.lo_shipmode = 'AIR'
      AND lo.lo_orderpriority = '1-URGENT'
)
SELECT
    cust_region,
    supp_region,
    d_year,
    p_category,
    COUNT(DISTINCT lo_orderkey) AS order_cnt,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_discount) AS total_discount,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_extendedprice) AS total_extendedprice,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_days_to_commit
FROM order_details
GROUP BY cust_region, supp_region, d_year, p_category
ORDER BY total_revenue DESC
LIMIT 20
