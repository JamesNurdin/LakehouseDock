WITH supplier_sales AS (
    SELECT
        supplier.s_suppkey,
        supplier.s_name,
        supplier.s_region,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_supplycost) AS total_supplycost,
        COUNT(*) AS line_count,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN supplier ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE lineorder.lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY supplier.s_suppkey, supplier.s_name, supplier.s_region
)
SELECT
    s_suppkey,
    s_name,
    s_region,
    total_revenue,
    total_supplycost,
    total_revenue - total_supplycost AS profit,
    line_count,
    avg_discount,
    RANK() OVER (PARTITION BY s_region ORDER BY (total_revenue - total_supplycost) DESC) AS profit_rank_in_region
FROM supplier_sales
ORDER BY s_region, profit_rank_in_region
