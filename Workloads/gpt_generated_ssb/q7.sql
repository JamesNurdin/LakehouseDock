WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_extendedprice) AS total_extendedprice,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(DATE_DIFF('day', CAST(od.order_date AS date), CAST(od.commit_date AS date))) AS avg_lead_time_days
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
GROUP BY od.order_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 100
