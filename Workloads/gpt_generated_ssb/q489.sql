WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE od.d_year = '1995'
)
SELECT
    od.order_year,
    cust.c_region,
    part.p_category,
    sup.s_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dates od
JOIN customer cust ON od.lo_custkey = cust.c_custkey
JOIN part part ON od.lo_partkey = part.p_partkey
JOIN supplier sup ON od.lo_suppkey = sup.s_suppkey
GROUP BY
    od.order_year,
    cust.c_region,
    part.p_category,
    sup.s_region
ORDER BY total_revenue DESC
LIMIT 10
