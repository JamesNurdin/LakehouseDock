WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        date_diff('day', CAST(d_ord.d_date AS DATE), CAST(d_com.d_date AS DATE)) AS days_to_commit
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
    WHERE d_ord.d_year = '1995'
)
SELECT
    order_year,
    order_month,
    COUNT(DISTINCT lo_orderkey) AS num_orders,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
    AVG(days_to_commit) AS avg_days_to_commit
FROM order_commit
GROUP BY order_year, order_month
ORDER BY order_year, order_month
