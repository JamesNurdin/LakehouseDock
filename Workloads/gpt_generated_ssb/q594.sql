WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1994'
)
SELECT
    order_year,
    order_month,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', DATE(order_date), DATE(commit_date))) AS avg_days_to_commit,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_commit
GROUP BY order_year, order_month
ORDER BY total_revenue DESC
LIMIT 10
