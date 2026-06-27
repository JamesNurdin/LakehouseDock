WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year AS order_year,
        CAST(d_order.d_daynuminyear AS integer) AS order_daynum,
        CAST(d_commit.d_daynuminyear AS integer) AS commit_daynum,
        c.c_nation,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1997'
)
SELECT
    c_nation,
    p_category,
    order_year,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(commit_daynum - order_daynum) AS avg_lead_time_days
FROM order_dim
GROUP BY c_nation, p_category, order_year
ORDER BY total_revenue DESC
LIMIT 50
