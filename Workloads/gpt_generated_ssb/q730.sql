WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od.d_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE od.d_year = '1995'
)
SELECT
    s.s_region AS supplier_region,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    oc.d_year AS order_year,
    SUM(oc.lo_revenue) AS total_revenue,
    AVG(oc.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(oc.order_date AS date), CAST(oc.commit_date AS date))) AS avg_lead_time_days,
    COUNT(*) AS order_count
FROM order_commit oc
JOIN supplier s ON oc.lo_suppkey = s.s_suppkey
JOIN part p ON oc.lo_partkey = p.p_partkey
JOIN customer c ON oc.lo_custkey = c.c_custkey
GROUP BY s.s_region, c.c_region, p.p_category, oc.d_year
ORDER BY total_revenue DESC
LIMIT 25
