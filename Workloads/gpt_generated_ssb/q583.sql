WITH order_info AS (
    SELECT
        s.s_region AS region,
        od.d_year AS year,
        od.d_month AS month,
        lo.lo_extendedprice AS extendedprice,
        lo.lo_revenue AS revenue,
        lo.lo_supplycost AS supplycost,
        lo.lo_quantity AS quantity,
        lo.lo_discount AS discount,
        lo.lo_orderkey AS orderkey,
        CAST(od.d_date AS date) AS order_date,
        CAST(cd.d_date AS date) AS commit_date
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE od.d_year = '1997'
)
SELECT
    region,
    year,
    month,
    SUM(extendedprice) AS total_extendedprice,
    SUM(revenue) AS total_revenue,
    SUM(supplycost) AS total_supplycost,
    SUM(revenue - supplycost) AS total_profit,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT orderkey) AS distinct_orders,
    AVG(discount) AS avg_discount,
    AVG(date_diff('day', order_date, commit_date)) AS avg_days_to_commit
FROM order_info
GROUP BY region, year, month
ORDER BY total_revenue DESC
