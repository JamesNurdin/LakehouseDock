/*
   Revenue and profit analysis by order year, customer region, part category, and supplier region
   for orders placed between 1995 and 1997.
*/
WITH order_dim AS (
    SELECT
        l.lo_orderkey,
        l.lo_custkey,
        l.lo_partkey,
        l.lo_suppkey,
        l.lo_revenue,
        l.lo_supplycost,
        d.d_year AS order_year,
        d.d_month AS order_month,
        d.d_date AS order_date
    FROM lineorder l
    JOIN dim_date d
        ON l.lo_orderdate = CAST(d.d_datekey AS integer)
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    s.s_region AS supplier_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_order_cnt
FROM order_dim od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year BETWEEN '1995' AND '1997'
GROUP BY od.order_year, c.c_region, p.p_category, s.s_region
ORDER BY od.order_year, c.c_region, p.p_category
