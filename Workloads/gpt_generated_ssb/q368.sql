WITH order_fact AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_custkey,
        lo_partkey,
        lo_suppkey
    FROM lineorder
)
SELECT
    d_order.d_year AS order_year,
    d_order.d_month AS order_month,
    p.p_category,
    s.s_region,
    SUM(order_fact.lo_revenue) AS total_revenue,
    SUM(order_fact.lo_revenue - order_fact.lo_supplycost) AS total_profit,
    AVG(order_fact.lo_discount) AS avg_discount,
    COUNT(DISTINCT order_fact.lo_orderkey) AS distinct_orders
FROM order_fact
JOIN dim_date d_order
    ON order_fact.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
JOIN dim_date d_commit
    ON order_fact.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
JOIN customer c
    ON order_fact.lo_custkey = c.c_custkey
JOIN part p
    ON order_fact.lo_partkey = p.p_partkey
JOIN supplier s
    ON order_fact.lo_suppkey = s.s_suppkey
WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY d_order.d_year, d_order.d_month, p.p_category, s.s_region
ORDER BY d_order.d_year, d_order.d_month, total_revenue DESC
