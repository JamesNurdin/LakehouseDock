WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    WHERE od.d_year = '1995'
      AND od.d_sellingseason = 'Holiday'
)
SELECT
    order_year,
    order_month,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', date(order_date), date(commit_date))) AS avg_lead_time_days,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_data
GROUP BY order_year, order_month
ORDER BY order_year, order_month
