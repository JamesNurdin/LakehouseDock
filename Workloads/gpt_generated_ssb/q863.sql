WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        od.d_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    WHERE od.d_year = '1995'
)
SELECT
    o.d_year,
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS order_count
FROM orders_1995 o
JOIN customer c ON o.lo_custkey = c.c_custkey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
GROUP BY o.d_year, c.c_region, p.p_category, s.s_nation
ORDER BY o.d_year, total_revenue DESC
