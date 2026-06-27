WITH lo_with_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    WHERE d_order.d_year = '1995'
)

SELECT
    order_year,
    order_month,
    lo_shipmode,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_days_to_commit,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_with_dates
GROUP BY order_year, order_month, lo_shipmode
ORDER BY total_revenue DESC
LIMIT 10
