WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_ord.d_date AS order_date,
        d_com.d_year AS commit_year,
        d_com.d_month AS commit_month,
        d_com.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_ord
        ON lo.lo_orderdate = CAST(d_ord.d_datekey AS INTEGER)
    JOIN dim_date d_com
        ON lo.lo_commitdate = CAST(d_com.d_datekey AS INTEGER)
    WHERE d_ord.d_year = '1995'
)
SELECT
    od.order_year,
    od.order_month,
    od.lo_shipmode,
    COUNT(DISTINCT od.lo_orderkey) AS order_cnt,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount
FROM order_dates od
GROUP BY od.order_year, od.order_month, od.lo_shipmode
ORDER BY od.order_year, od.order_month, od.lo_shipmode
