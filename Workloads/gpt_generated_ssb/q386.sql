WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_discount,
        c.c_region,
        c.c_mktsegment,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    c_region,
    c_mktsegment,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_days_to_commit,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_commit
GROUP BY
    c_region,
    c_mktsegment,
    order_year
ORDER BY
    total_revenue DESC
LIMIT 100
