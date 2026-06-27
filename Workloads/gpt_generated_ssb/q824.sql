WITH filtered_orders AS (
    SELECT
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_quantity,
        lineorder.lo_discount,
        lineorder.lo_custkey,
        dim_date.d_year,
        supplier.s_region,
        customer.c_region
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE part.p_category = 'MFGR#1'
      AND dim_date.d_year = '1997'
)
SELECT
    filtered_orders.d_year,
    filtered_orders.s_region,
    filtered_orders.c_region,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_supplycost) AS total_supply_cost,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    SUM(filtered_orders.lo_quantity) AS total_quantity,
    AVG(filtered_orders.lo_discount) AS avg_discount,
    COUNT(DISTINCT filtered_orders.lo_custkey) AS distinct_customers
FROM filtered_orders
GROUP BY filtered_orders.d_year, filtered_orders.s_region, filtered_orders.c_region
ORDER BY filtered_orders.d_year, filtered_orders.s_region, total_revenue DESC
