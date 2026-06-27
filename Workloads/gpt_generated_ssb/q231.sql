WITH order_data AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_quantity
    FROM lineorder
    WHERE lo_quantity > 0
)
SELECT
    d.d_year,
    s.s_region,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS num_orders
FROM order_data o
JOIN dim_date d ON CAST(d.d_datekey AS integer) = o.lo_orderdate
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1995'
GROUP BY d.d_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
