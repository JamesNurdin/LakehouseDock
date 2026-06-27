WITH order_details AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_commitdate,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost
    FROM lineorder
)
SELECT
    d_year.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_details od
JOIN dim_date d_year
    ON od.lo_orderdate = CAST(d_year.d_datekey AS integer)
JOIN dim_date cd
    ON od.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE d_year.d_year BETWEEN '1992' AND '1998'
GROUP BY d_year.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
