SELECT
    c.c_region,
    od.d_year AS order_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(DATE_DIFF('day', CAST(od.d_date AS DATE), CAST(cd.d_date AS DATE))) AS avg_days_to_commit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date od
    ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd
    ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
GROUP BY c.c_region, od.d_year
ORDER BY total_revenue DESC
