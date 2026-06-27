WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    s.s_region,
    od.d_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_extendedprice) AS total_extended_price,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1997'
GROUP BY s.s_region, od.d_year
ORDER BY total_revenue DESC
