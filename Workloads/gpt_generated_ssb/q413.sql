WITH revenue_by_category AS (
    SELECT
        c.c_region AS region,
        d.d_year AS year,
        p.p_category AS category,
        SUM(lo.lo_revenue) AS category_revenue
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1995'
    GROUP BY c.c_region, d.d_year, p.p_category
)
SELECT
    region,
    year,
    category,
    category_revenue,
    RANK() OVER (PARTITION BY region, year ORDER BY category_revenue DESC) AS revenue_rank
FROM revenue_by_category
ORDER BY region, year, revenue_rank
LIMIT 20
