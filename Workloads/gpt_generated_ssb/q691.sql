WITH monthly_region_category AS (
    SELECT
        dd.d_year,
        dd.d_month,
        p.p_category,
        s.s_region,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN dim_date dd
        ON lo.lo_orderdate = CAST(dd.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE dd.d_year = '1995'
    GROUP BY dd.d_year, dd.d_month, p.p_category, s.s_region
)
SELECT
    d_year,
    d_month,
    p_category,
    s_region,
    revenue,
    profit,
    avg_discount,
    order_cnt,
    revenue / SUM(revenue) OVER (PARTITION BY d_year, d_month, p_category) AS revenue_share
FROM monthly_region_category
ORDER BY revenue DESC
LIMIT 100
