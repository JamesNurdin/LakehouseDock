WITH order_data AS (
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
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
)
SELECT
    s.s_region,
    od.order_year,
    od.order_month,
    SUM(od.lo_extendedprice) AS total_extended_price,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_data od
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
WHERE CAST(od.order_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY s.s_region, od.order_year, od.order_month
ORDER BY s.s_region, od.order_year, od.order_month
