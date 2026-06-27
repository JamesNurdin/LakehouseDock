WITH revenue_by_year_category AS (
    SELECT
        dim_date.d_year AS order_year,
        part.p_category AS category,
        supplier.s_region AS supplier_region,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_quantity) AS total_quantity,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(DISTINCT lineorder.lo_custkey) AS distinct_customers
    FROM lineorder
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS varchar) = dim_date.d_datekey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE CAST(dim_date.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
    GROUP BY dim_date.d_year, part.p_category, supplier.s_region
)
SELECT
    order_year,
    category,
    supplier_region,
    total_revenue,
    total_quantity,
    avg_discount,
    distinct_customers,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank_within_year,
    total_revenue - LAG(total_revenue) OVER (PARTITION BY category ORDER BY order_year) AS revenue_change_vs_prev_year,
    CASE
        WHEN LAG(total_revenue) OVER (PARTITION BY category ORDER BY order_year) IS NULL THEN NULL
        ELSE (total_revenue - LAG(total_revenue) OVER (PARTITION BY category ORDER BY order_year)) * 100.0 / LAG(total_revenue) OVER (PARTITION BY category ORDER BY order_year)
    END AS revenue_growth_pct
FROM revenue_by_year_category
ORDER BY order_year, total_revenue DESC
LIMIT 100
