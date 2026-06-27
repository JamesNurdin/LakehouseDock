SELECT
    od.d_year AS order_year,
    od.d_month AS order_month,
    cd.d_year AS commit_year,
    cd.d_month AS commit_month,
    COUNT(*) AS order_count,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date od
    ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd
    ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
WHERE od.d_year = '1995'
GROUP BY od.d_year, od.d_month, cd.d_year, cd.d_month
ORDER BY od.d_year, od.d_month, cd.d_year, cd.d_month
