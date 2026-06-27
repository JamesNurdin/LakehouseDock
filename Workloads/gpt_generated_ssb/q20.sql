WITH filtered_lineorder AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_partkey,
        lo.lo_revenue
    FROM lineorder lo
    JOIN dim_date cd
      ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE cd.d_month = '12'
),
revenue_by_year_category AS (
    SELECT
        od.d_year AS d_year,
        p.p_category AS p_category,
        SUM(lo.lo_revenue) AS total_revenue
    FROM filtered_lineorder lo
    JOIN dim_date od
      ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    GROUP BY od.d_year, p.p_category
),
ranked_revenue AS (
    SELECT
        d_year,
        p_category,
        total_revenue,
        RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
    FROM revenue_by_year_category
)
SELECT
    d_year,
    p_category,
    total_revenue,
    revenue_rank
FROM ranked_revenue
WHERE revenue_rank <= 5
ORDER BY d_year, revenue_rank
