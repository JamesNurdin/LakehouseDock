WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
)
SELECT
    od.order_year,
    c.c_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.commit_date AS date), CAST(od.order_date AS date))) AS avg_lead_time_days
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
WHERE od.order_year = '1995'
GROUP BY od.order_year, c.c_region
ORDER BY total_revenue DESC
