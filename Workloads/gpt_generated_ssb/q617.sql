WITH order_dates AS (
    SELECT
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_custkey,
        d_year,
        d_month
    FROM lineorder
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS VARCHAR) = dim_date.d_datekey
    WHERE dim_date.d_year = '1997'
)
SELECT
    d_year,
    d_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_custkey) AS distinct_customers
FROM order_dates
GROUP BY d_year, d_month
ORDER BY total_revenue DESC
