WITH revenue_by_region_category AS (
    SELECT
        d.d_year,
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_date BETWEEN '1993-01-01' AND '1995-12-31'
    GROUP BY d.d_year, s.s_region, p.p_category
)
SELECT
    r.d_year,
    r.s_region,
    r.p_category,
    r.total_revenue,
    RANK() OVER (PARTITION BY r.d_year, r.s_region ORDER BY r.total_revenue DESC) AS revenue_rank,
    (r.total_revenue * 100.0) / SUM(r.total_revenue) OVER (PARTITION BY r.d_year) AS revenue_pct_year
FROM revenue_by_region_category r
ORDER BY r.d_year, r.s_region, revenue_rank
