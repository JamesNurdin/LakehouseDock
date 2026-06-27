WITH monthly_profit AS (
    SELECT
        d.d_year,
        d.d_monthnuminyear,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
        SUM(lo.lo_revenue) AS revenue,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    GROUP BY d.d_year, d.d_monthnuminyear, c.c_region, p.p_category
)
SELECT
    mp.d_year,
    mp.d_monthnuminyear,
    mp.c_region,
    mp.p_category,
    mp.profit,
    mp.revenue,
    mp.order_cnt,
    LAG(mp.profit) OVER (
        PARTITION BY mp.c_region, mp.p_category
        ORDER BY CAST(mp.d_year AS INTEGER), CAST(mp.d_monthnuminyear AS INTEGER)
    ) AS profit_prev_month,
    mp.profit - LAG(mp.profit) OVER (
        PARTITION BY mp.c_region, mp.p_category
        ORDER BY CAST(mp.d_year AS INTEGER), CAST(mp.d_monthnuminyear AS INTEGER)
    ) AS profit_change
FROM monthly_profit mp
WHERE mp.d_year = '1997'
ORDER BY mp.c_region, mp.p_category, CAST(mp.d_monthnuminyear AS INTEGER)
