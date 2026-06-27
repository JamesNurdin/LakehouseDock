WITH filtered_orders AS (
    SELECT
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        part.p_category AS product_category,
        supplier.s_region AS supplier_region,
        customer.c_region AS customer_region,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_discount
    FROM lineorder
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lineorder.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lineorder.lo_commitdate
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND CAST(d_commit.d_date AS DATE) >= CAST(d_order.d_date AS DATE)
),
aggregated AS (
    SELECT
        order_year,
        order_month,
        product_category,
        supplier_region,
        customer_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount
    FROM filtered_orders
    GROUP BY order_year, order_month, product_category, supplier_region, customer_region
)
SELECT
    order_year,
    order_month,
    product_category,
    supplier_region,
    customer_region,
    total_revenue,
    total_profit,
    avg_discount,
    SUM(total_revenue) OVER (PARTITION BY order_year ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue_year
FROM aggregated
ORDER BY order_year, order_month, total_revenue DESC
LIMIT 200
