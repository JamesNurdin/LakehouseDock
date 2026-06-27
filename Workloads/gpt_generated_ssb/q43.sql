WITH revenue_by_year_category AS (
    SELECT
        dim_date.d_year,
        part.p_category,
        SUM(lineorder.lo_revenue) AS total_revenue,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(DISTINCT lineorder.lo_orderkey) AS order_count
    FROM lineorder
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS varchar) = dim_date.d_datekey
    WHERE dim_date.d_year = '1997'
    GROUP BY dim_date.d_year, part.p_category
)
SELECT
    d_year,
    p_category,
    total_revenue,
    avg_discount,
    order_count,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_year_category
ORDER BY total_revenue DESC
