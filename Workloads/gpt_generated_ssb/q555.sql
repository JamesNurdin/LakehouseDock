WITH order_join AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_shipmode,
        od.d_year   AS order_year,
        od.d_month  AS order_month,
        od.d_yearmonth AS order_year_month,
        cd.d_year   AS commit_year,
        cd.d_month  AS commit_month,
        cd.d_yearmonth AS commit_year_month
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
    lo_shipmode,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_revenue)        AS total_revenue,
    SUM(lo_quantity)       AS total_quantity,
    AVG(lo_discount)       AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_join
GROUP BY
    order_year,
    order_month,
    lo_shipmode
ORDER BY
    order_year,
    order_month,
    lo_shipmode
