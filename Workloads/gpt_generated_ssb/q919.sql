WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_discount,
        od.d_year AS order_year,
        CAST(od.d_date AS date) AS order_date,
        cd.d_year AS commit_year,
        CAST(cd.d_date AS date) AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1997'
)
SELECT
    oc.order_year,
    s.s_region,
    p.p_category,
    COUNT(*) AS order_count,
    SUM(oc.lo_revenue) AS total_revenue,
    AVG(date_diff('day', oc.order_date, oc.commit_date)) AS avg_lead_time_days
FROM order_commit oc
JOIN part p
    ON oc.lo_partkey = p.p_partkey
JOIN supplier s
    ON oc.lo_suppkey = s.s_suppkey
GROUP BY oc.order_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
