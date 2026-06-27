WITH revenue_by_region_month AS (
    SELECT
        d.d_year,
        d.d_month,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY d.d_year, d.d_month, s.s_region
)
SELECT
    d_year,
    d_month,
    s_region,
    total_revenue,
    total_profit,
    RANK() OVER (PARTITION BY d_year, d_month ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY d_year, d_month) AS month_total_profit,
    total_profit / SUM(total_profit) OVER (PARTITION BY d_year, d_month) AS profit_share
FROM revenue_by_region_month
ORDER BY d_year, d_month, profit_rank
