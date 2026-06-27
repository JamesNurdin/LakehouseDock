WITH order_base AS (
    SELECT
        lo_orderkey,
        lo_orderdate,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_quantity
    FROM lineorder
    WHERE lo_quantity > 0
)
SELECT
    order_date_dim.d_year AS order_year,
    customer.c_region AS customer_region,
    part.p_category AS part_category,
    SUM(order_base.lo_revenue) AS total_revenue,
    SUM(order_base.lo_revenue - order_base.lo_supplycost) AS total_profit,
    COUNT(DISTINCT order_base.lo_orderkey) AS order_count
FROM order_base
JOIN dim_date AS order_date_dim
    ON CAST(order_base.lo_orderdate AS VARCHAR) = order_date_dim.d_datekey
JOIN customer
    ON order_base.lo_custkey = customer.c_custkey
JOIN part
    ON order_base.lo_partkey = part.p_partkey
JOIN supplier
    ON order_base.lo_suppkey = supplier.s_suppkey
WHERE CAST(order_date_dim.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY order_date_dim.d_year, customer.c_region, part.p_category
ORDER BY order_date_dim.d_year, total_revenue DESC
