WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_shipmode,
        od.d_date AS order_date,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_yearmonth AS order_yearmonth,
        cd.d_date AS commit_date,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        cd.d_yearmonth AS commit_yearmonth
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
)

SELECT
    order_year,
    order_month,
    order_yearmonth,
    lo_shipmode,
    SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    AVG(DATE_DIFF('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_lead_time_days,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_dim
GROUP BY order_year, order_month, order_yearmonth, lo_shipmode
ORDER BY order_year, order_month, lo_shipmode
