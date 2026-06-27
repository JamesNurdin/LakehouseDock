WITH orders_air AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_shipmode,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
)
SELECT
    od.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS product_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders,
    MIN(od.d_date) AS earliest_order_date,
    MAX(cd.d_date) AS latest_commit_date
FROM orders_air o
JOIN dim_date od ON CAST(od.d_datekey AS integer) = o.lo_orderdate
JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = o.lo_commitdate
JOIN customer c ON o.lo_custkey = c.c_custkey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 100
