WITH monthly_category_region_rev AS (
    SELECT
        d.d_year,
        d.d_month,
        p.p_category,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
    GROUP BY d.d_year, d.d_month, p.p_category, s.s_region
)
SELECT
    d_year,
    d_month,
    p_category,
    s_region,
    total_revenue,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month ORDER BY total_revenue DESC) AS category_rank
FROM monthly_category_region_rev
ORDER BY d_year, d_month, category_rank
LIMIT 20
