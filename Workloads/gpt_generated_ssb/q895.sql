WITH region_year_revenue AS (
    SELECT
        s.s_region AS s_region,
        d.d_year AS d_year,
        SUM(lo.lo_revenue) AS revenue
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    GROUP BY s.s_region, d.d_year
),
ranked_regions AS (
    SELECT
        s_region,
        d_year,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY revenue DESC) AS revenue_rank
    FROM region_year_revenue
)
SELECT
    s_region,
    d_year,
    revenue,
    revenue_rank
FROM ranked_regions
WHERE revenue_rank <= 3
ORDER BY d_year, revenue_rank
