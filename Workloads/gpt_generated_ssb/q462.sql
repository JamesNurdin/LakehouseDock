WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_quantity,
        lo_tax,
        dim_date.d_date
    FROM lineorder
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS varchar) = dim_date.d_datekey
    WHERE dim_date.d_date BETWEEN '1995-01-01' AND '1995-12-31'
)
SELECT
    customer.c_region,
    customer.c_nation,
    part.p_category,
    supplier.s_region AS supplier_region,
    sum(filtered_orders.lo_revenue) AS total_revenue,
    sum(filtered_orders.lo_supplycost) AS total_supply_cost,
    sum(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    avg(filtered_orders.lo_discount) AS avg_discount
FROM filtered_orders
JOIN customer
    ON filtered_orders.lo_custkey = customer.c_custkey
JOIN part
    ON filtered_orders.lo_partkey = part.p_partkey
JOIN supplier
    ON filtered_orders.lo_suppkey = supplier.s_suppkey
GROUP BY
    customer.c_region,
    customer.c_nation,
    part.p_category,
    supplier.s_region
ORDER BY total_revenue DESC
LIMIT 10
