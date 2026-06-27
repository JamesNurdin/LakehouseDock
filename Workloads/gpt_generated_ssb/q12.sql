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
        od.d_date AS order_date,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_dayofweek AS order_dayofweek,
        cd.d_date AS commit_date,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    order_dates.order_year,
    supplier.s_region,
    part.p_category,
    SUM(order_dates.lo_revenue) AS total_revenue,
    SUM(order_dates.lo_revenue - order_dates.lo_supplycost) AS total_profit,
    AVG(order_dates.lo_discount) AS avg_discount,
    AVG(order_dates.lo_commitdate - order_dates.lo_orderdate) AS avg_lead_time_days,
    COUNT(DISTINCT order_dates.lo_orderkey) AS distinct_orders
FROM order_dates
JOIN customer
    ON order_dates.lo_custkey = customer.c_custkey
JOIN part
    ON order_dates.lo_partkey = part.p_partkey
JOIN supplier
    ON order_dates.lo_suppkey = supplier.s_suppkey
WHERE order_dates.order_year = '1995'
GROUP BY order_dates.order_year, supplier.s_region, part.p_category
ORDER BY total_revenue DESC
LIMIT 20
