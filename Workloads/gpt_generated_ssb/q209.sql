WITH order_data AS (
    SELECT
        customer.c_region AS customer_region,
        supplier.s_region AS supplier_region,
        part.p_category,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_discount,
        lineorder.lo_orderkey
    FROM lineorder
    JOIN customer ON lineorder.lo_custkey = customer.c_custkey
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN dim_date d_order ON CAST(lineorder.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit ON CAST(lineorder.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    WHERE CAST(d_order.d_date AS DATE) >= DATE '1995-01-01'
      AND CAST(d_order.d_date AS DATE) < DATE '1996-01-01'
)
SELECT
    customer_region,
    supplier_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(*) AS lineitem_count
FROM order_data
GROUP BY
    customer_region,
    supplier_region,
    p_category
HAVING SUM(lo_revenue) - SUM(lo_supplycost) > 0
ORDER BY profit DESC
LIMIT 20
