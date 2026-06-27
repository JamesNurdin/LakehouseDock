WITH base AS (
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
        lo.lo_shipmode,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE CAST(od.d_year AS INTEGER) BETWEEN 1995 AND 1997
),
agg AS (
    SELECT
        cust_region,
        order_year,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        SUM(lo_supplycost) AS total_supplycost
    FROM base
    GROUP BY
        cust_region,
        order_year,
        p_category
)
SELECT
    cust_region,
    order_year,
    p_category,
    total_revenue,
    avg_discount,
    distinct_orders,
    total_supplycost,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank_by_year
FROM agg
ORDER BY total_revenue DESC
LIMIT 100
