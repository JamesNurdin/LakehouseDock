WITH monthly_revenue AS (
    SELECT
        od.d_year AS d_year,
        od.d_month AS d_month,
        od.d_monthnuminyear AS d_monthnuminyear,
        p.p_category AS p_category,
        s.s_region AS s_region,
        sum(lo.lo_revenue) AS monthly_revenue,
        sum(lo.lo_revenue - lo.lo_supplycost) AS monthly_profit
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY od.d_year, od.d_month, od.d_monthnuminyear, p.p_category, s.s_region
)
SELECT
    d_year,
    d_month,
    p_category,
    s_region,
    monthly_revenue,
    monthly_profit,
    sum(monthly_revenue) OVER (
        PARTITION BY d_year, p_category, s_region
        ORDER BY CAST(d_monthnuminyear AS integer)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue,
    rank() OVER (PARTITION BY d_year ORDER BY monthly_revenue DESC) AS month_revenue_rank
FROM monthly_revenue
ORDER BY d_year, CAST(d_monthnuminyear AS integer)
