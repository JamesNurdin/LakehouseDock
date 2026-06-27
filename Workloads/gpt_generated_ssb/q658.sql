WITH order_summary AS (
    SELECT
        od.d_year AS year,
        c.c_region AS region,
        p.p_category AS category,
        SUM(lo.lo_revenue) AS revenue
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE cd.d_holidayfl = 'N'
    GROUP BY od.d_year, c.c_region, p.p_category
),
ranked_summary AS (
    SELECT
        year,
        region,
        category,
        revenue,
        revenue / SUM(revenue) OVER (PARTITION BY year, region) AS revenue_share,
        ROW_NUMBER() OVER (PARTITION BY year, region ORDER BY revenue DESC) AS rn
    FROM order_summary
)
SELECT
    year,
    region,
    category,
    revenue,
    revenue_share
FROM ranked_summary
WHERE rn <= 5
ORDER BY year, region, revenue_share DESC
