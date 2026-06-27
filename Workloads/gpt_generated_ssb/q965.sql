WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
)
SELECT
    d.d_year,
    s.s_region,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_supplycost) AS total_supplycost,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_order_count
FROM orders o
JOIN dim_date d ON CAST(o.lo_orderdate AS varchar) = d.d_datekey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1997'
GROUP BY d.d_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
