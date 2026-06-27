SELECT
    order_date.d_year AS order_year,
    order_date.d_yearmonth AS order_year_month,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    AVG(lineorder.lo_discount) AS avg_discount,
    COUNT(DISTINCT lineorder.lo_orderkey) AS distinct_orders,
    AVG(date_diff('day', CAST(order_date.d_date AS DATE), CAST(commit_date.d_date AS DATE))) AS avg_days_to_commit
FROM lineorder
JOIN dim_date AS order_date
    ON CAST(lineorder.lo_orderdate AS VARCHAR) = order_date.d_datekey
JOIN dim_date AS commit_date
    ON CAST(lineorder.lo_commitdate AS VARCHAR) = commit_date.d_datekey
WHERE order_date.d_year = '1997'
GROUP BY
    order_date.d_year,
    order_date.d_yearmonth
ORDER BY
    order_date.d_yearmonth
