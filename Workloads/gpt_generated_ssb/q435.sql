WITH order_data AS (
    SELECT
        dim_date.d_year,
        customer.c_region,
        supplier.s_region,
        part.p_category,
        lineorder.lo_orderkey,
        lineorder.lo_revenue,
        lineorder.lo_supplycost
    FROM lineorder
    JOIN dim_date
        ON CAST(dim_date.d_datekey AS INTEGER) = lineorder.lo_orderdate
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE dim_date.d_year BETWEEN '1995' AND '1997'
)
SELECT
    d_year,
    c_region,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_data
GROUP BY d_year, c_region, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
