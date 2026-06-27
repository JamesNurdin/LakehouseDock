WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        CAST(od.d_year AS integer) AS order_year,
        CAST(cd.d_year AS integer) AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    s.s_name,
    od.order_year,
    SUM(od.lo_quantity) AS total_quantity,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = 1995
GROUP BY s.s_name, od.order_year
ORDER BY total_revenue DESC
LIMIT 10
