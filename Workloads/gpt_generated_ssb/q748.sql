WITH filtered_orders AS (
    SELECT
        lo_orderdate,
        lo_commitdate,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_shipmode
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
)
SELECT
    order_date.d_year            AS order_year,
    customer.c_region            AS customer_region,
    part.p_category              AS product_category,
    SUM(filtered_orders.lo_revenue)                                         AS total_revenue,
    SUM(filtered_orders.lo_extendedprice * (1 - filtered_orders.lo_discount / 100.0)) AS net_sales,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost)         AS total_profit,
    COUNT(DISTINCT filtered_orders.lo_custkey)                               AS distinct_customers,
    COUNT(DISTINCT filtered_orders.lo_suppkey)                               AS distinct_suppliers
FROM filtered_orders
JOIN dim_date AS order_date
    ON filtered_orders.lo_orderdate = CAST(order_date.d_datekey AS integer)
JOIN dim_date AS commit_date
    ON filtered_orders.lo_commitdate = CAST(commit_date.d_datekey AS integer)
JOIN customer
    ON filtered_orders.lo_custkey = customer.c_custkey
JOIN part
    ON filtered_orders.lo_partkey = part.p_partkey
JOIN supplier
    ON filtered_orders.lo_suppkey = supplier.s_suppkey
WHERE CAST(order_date.d_date AS date) >= DATE '1995-01-01'
  AND CAST(order_date.d_date AS date) <  DATE '1996-01-01'
  AND customer.c_mktsegment = 'AUTOMOBILE'
GROUP BY
    order_date.d_year,
    customer.c_region,
    part.p_category
ORDER BY
    order_date.d_year,
    total_revenue DESC
LIMIT 100
