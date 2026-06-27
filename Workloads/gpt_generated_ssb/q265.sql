WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        od.d_year AS order_year,
        od.d_month AS order_month,
        CAST(od.d_date AS date) AS order_date,
        CAST(cd.d_date AS date) AS commit_date,
        DATE_DIFF('day', CAST(od.d_date AS date), CAST(cd.d_date AS date)) AS lead_days,
        lo.lo_revenue,
        lo.lo_supplycost,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
)
SELECT
    order_year,
    order_month,
    p_category,
    s_region,
    COUNT(*) AS order_count,
    AVG(lead_days) AS avg_lead_days,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit
FROM order_commit
GROUP BY order_year, order_month, p_category, s_region
HAVING SUM(lo_revenue) > 1000000
ORDER BY order_year, order_month, total_revenue DESC
