WITH lo_metrics AS (
    SELECT
        dim_date.d_year AS order_year,
        customer.c_region AS customer_region,
        supplier.s_region AS supplier_region,
        part.p_category AS product_category,
        lineorder.lo_quantity,
        lineorder.lo_discount,
        lineorder.lo_extendedprice,
        lineorder.lo_quantity * lineorder.lo_supplycost AS supply_cost,
        lineorder.lo_extendedprice * (100 - lineorder.lo_discount) / 100.0 AS revenue
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS INTEGER)
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE dim_date.d_year IN ('1994', '1995')
)
SELECT
    order_year,
    customer_region,
    supplier_region,
    product_category,
    SUM(revenue) AS total_revenue,
    SUM(supply_cost) AS total_supply_cost,
    SUM(revenue) - SUM(supply_cost) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount
FROM lo_metrics
GROUP BY order_year, customer_region, supplier_region, product_category
ORDER BY order_year, total_revenue DESC
