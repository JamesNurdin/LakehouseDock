WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        od.d_year,
        od.d_month,
        CAST(cd.d_monthnuminyear AS integer) - CAST(od.d_monthnuminyear AS integer) AS months_to_commit
    FROM lineorder AS lo
    JOIN dim_date AS od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date AS cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    WHERE od.d_year = '1997'
)
SELECT
    d_year,
    d_month,
    SUM(lo_revenue) AS total_revenue,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    AVG(months_to_commit) AS avg_months_to_commit
FROM order_commit
GROUP BY d_year, d_month
ORDER BY d_year, d_month
