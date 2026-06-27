WITH order_base AS (
    SELECT
        CAST(lo_orderdate AS varchar) AS order_date_key,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
)
SELECT
    d.d_year AS year,
    c.c_region AS region,
    p.p_category AS category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_supplycost) AS total_supply_cost,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount
FROM order_base o
JOIN dim_date d ON o.order_date_key = d.d_datekey
JOIN customer c ON o.lo_custkey = c.c_custkey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1995'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
