WITH filtered_orders AS (
    SELECT
        lineorder.lo_orderkey,
        lineorder.lo_linenumber,
        lineorder.lo_custkey,
        lineorder.lo_partkey,
        lineorder.lo_suppkey,
        lineorder.lo_orderdate,
        lineorder.lo_discount,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        dim_date.d_year,
        dim_date.d_month,
        customer.c_mktsegment,
        part.p_category,
        supplier.s_region
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS INTEGER)
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE dim_date.d_year = '1995'
      AND lineorder.lo_discount BETWEEN 5 AND 10
)
SELECT
    filtered_orders.d_year,
    filtered_orders.d_month,
    filtered_orders.p_category,
    filtered_orders.s_region,
    filtered_orders.c_mktsegment,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit
FROM filtered_orders
GROUP BY
    filtered_orders.d_year,
    filtered_orders.d_month,
    filtered_orders.p_category,
    filtered_orders.s_region,
    filtered_orders.c_mktsegment
ORDER BY
    filtered_orders.d_year,
    filtered_orders.d_month,
    filtered_orders.p_category,
    filtered_orders.s_region,
    filtered_orders.c_mktsegment
