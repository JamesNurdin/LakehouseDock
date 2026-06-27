WITH monthly_agg AS (
    SELECT
        dim_date.d_year,
        dim_date.d_month,
        SUM(lineorder.lo_revenue) AS monthly_revenue,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(DISTINCT lineorder.lo_orderkey) AS distinct_orders
    FROM lineorder
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS VARCHAR) = dim_date.d_datekey
    WHERE dim_date.d_year IN ('1997', '1998')
    GROUP BY dim_date.d_year, dim_date.d_month
)
SELECT
    d_year,
    d_month,
    monthly_revenue,
    avg_discount,
    distinct_orders,
    SUM(monthly_revenue) OVER (PARTITION BY d_year ORDER BY d_month) AS cumulative_revenue
FROM monthly_agg
ORDER BY d_year, d_month
