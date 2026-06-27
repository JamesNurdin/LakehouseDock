WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year AS order_year,
        od.d_month AS order_month,
        CAST(od.d_daynuminyear AS integer) AS order_daynum,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        CAST(cd.d_daynuminyear AS integer) AS commit_daynum
    FROM lineorder lo
    JOIN dim_date od
      ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
      ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE od.d_year = '1995'
)
SELECT
    order_year,
    order_month,
    COUNT(*) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(commit_daynum - order_daynum + (CAST(commit_year AS integer) - CAST(order_year AS integer)) * 365) AS avg_lag_days
FROM order_dates
GROUP BY
    order_year,
    order_month
ORDER BY
    order_year,
    order_month
