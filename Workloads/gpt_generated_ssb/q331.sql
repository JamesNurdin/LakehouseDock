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
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    od.order_year,
    od.commit_year,
    s.s_region,
    p.p_category,
    c.c_mktsegment,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(*) AS order_line_count
FROM order_dates od
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
JOIN part p ON od.lo_partkey = p.p_partkey
JOIN customer c ON od.lo_custkey = c.c_custkey
WHERE od.order_year BETWEEN '1995' AND '1997'
  AND od.lo_discount > 0
GROUP BY od.order_year, od.commit_year, s.s_region, p.p_category, c.c_mktsegment
ORDER BY od.order_year, od.commit_year, s.s_region, p.p_category, c.c_mktsegment
