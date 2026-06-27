WITH order_date AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year
    FROM lineorder AS lo
    JOIN dim_date AS d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
)
SELECT
    order_date.d_year AS year,
    customer.c_region AS region,
    part.p_category AS category,
    supplier.s_nation AS supplier_nation,
    SUM(order_date.lo_revenue) AS total_revenue,
    SUM(order_date.lo_revenue - order_date.lo_supplycost) AS total_profit,
    COUNT(DISTINCT order_date.lo_orderkey) AS distinct_orders
FROM order_date
JOIN customer
    ON order_date.lo_custkey = customer.c_custkey
JOIN part
    ON order_date.lo_partkey = part.p_partkey
JOIN supplier
    ON order_date.lo_suppkey = supplier.s_suppkey
GROUP BY
    order_date.d_year,
    customer.c_region,
    part.p_category,
    supplier.s_nation
HAVING SUM(order_date.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 20
