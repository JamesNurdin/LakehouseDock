-- Total revenue and profit by year and customer region for orders placed in 1998
WITH orders_1998 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE od.d_year = '1998'
)
SELECT
    o.d_year,
    c.c_region,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    COUNT(*) AS order_cnt
FROM orders_1998 o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
GROUP BY o.d_year, c.c_region
ORDER BY total_revenue DESC
