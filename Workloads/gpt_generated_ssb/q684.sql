WITH order_agg AS (
    SELECT
        dim_date.d_year AS order_year,
        supplier.s_region AS supplier_region,
        part.p_category AS part_category,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_supplycost) AS total_supplycost,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder
    JOIN dim_date
        ON CAST(dim_date.d_datekey AS integer) = lineorder.lo_orderdate
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    WHERE dim_date.d_year = '1995'
      AND customer.c_mktsegment = 'AUTOMOBILE'
    GROUP BY dim_date.d_year, supplier.s_region, part.p_category
)
SELECT
    order_year,
    supplier_region,
    part_category,
    total_revenue,
    total_supplycost,
    total_revenue - total_supplycost AS profit,
    avg_discount,
    order_count
FROM order_agg
ORDER BY profit DESC
LIMIT 10
