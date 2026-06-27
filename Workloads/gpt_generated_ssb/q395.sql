WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        CAST(od_order.d_year AS INTEGER) AS order_year,
        od_order.d_date AS order_date,
        od_commit.d_date AS commit_date,
        date_diff('day', CAST(od_order.d_date AS DATE), CAST(od_commit.d_date AS DATE)) AS days_to_commit
    FROM lineorder lo
    JOIN dim_date od_order
        ON CAST(od_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date od_commit
        ON CAST(od_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE od_order.d_year = '1997'
)
SELECT
    oc.order_year,
    s.s_region,
    p.p_category,
    COUNT(DISTINCT oc.lo_orderkey) AS num_orders,
    SUM(oc.lo_revenue) AS total_revenue,
    SUM(oc.lo_revenue - oc.lo_supplycost) AS total_profit,
    AVG(oc.days_to_commit) AS avg_days_to_commit
FROM order_commit oc
JOIN customer c
    ON oc.lo_custkey = c.c_custkey
JOIN part p
    ON oc.lo_partkey = p.p_partkey
JOIN supplier s
    ON oc.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'AMERICA'
GROUP BY oc.order_year, s.s_region, p.p_category
ORDER BY oc.order_year, total_revenue DESC
