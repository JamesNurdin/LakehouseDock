WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    WHERE CAST(d_commit.d_year AS INTEGER) >= 1995
)
SELECT
    c.c_mktsegment,
    od.order_year,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    SUM(od.lo_quantity) AS total_quantity
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
GROUP BY c.c_mktsegment, od.order_year
ORDER BY total_revenue DESC
LIMIT 100
