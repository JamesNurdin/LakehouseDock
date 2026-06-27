WITH order_dates AS (
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
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_yearmonth AS order_yearmonth,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        cd.d_yearmonth AS commit_yearmonth
    FROM lineorder lo
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    order_year,
    order_month,
    lo_shipmode,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_revenue - lo_supplycost) / NULLIF(SUM(lo_revenue), 0) * 100 AS profit_margin_pct,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(*) AS line_items
FROM order_dates
WHERE order_year = '1995'
GROUP BY order_year, order_month, lo_shipmode
ORDER BY order_year, order_month, lo_shipmode
