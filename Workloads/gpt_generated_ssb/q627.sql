WITH lo_joined AS (
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
        od.d_year,
        od.d_month,
        od.d_yearmonth,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
)
SELECT
    d_year AS order_year,
    d_month AS order_month,
    d_yearmonth AS order_year_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    AVG(lo_discount) AS avg_discount
FROM lo_joined
WHERE commit_date > order_date
GROUP BY d_year, d_month, d_yearmonth
ORDER BY d_year, d_month
