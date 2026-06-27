WITH order_dim AS (
    SELECT CAST(d_datekey AS integer) AS datekey,
           d_year,
           d_date
    FROM dim_date
),
commit_dim AS (
    SELECT CAST(d_datekey AS integer) AS datekey,
           d_year AS commit_year,
           d_date AS commit_date
    FROM dim_date
),
agg AS (
    SELECT
        od.d_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS orders,
        COUNT(DISTINCT lo.lo_custkey) AS distinct_customers
    FROM lineorder lo
    JOIN order_dim od ON lo.lo_orderdate = od.datekey
    JOIN commit_dim cd ON lo.lo_commitdate = cd.datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year BETWEEN '1993' AND '1995'
      AND cd.commit_year >= od.d_year
      AND s.s_region = 'ASIA'
    GROUP BY od.d_year, c.c_region, p.p_category
)
SELECT
    a.d_year,
    a.c_region,
    a.p_category,
    a.revenue,
    a.profit,
    a.avg_discount,
    a.orders,
    a.distinct_customers,
    LAG(a.revenue) OVER (PARTITION BY a.c_region, a.p_category ORDER BY a.d_year) AS prev_year_revenue,
    (a.revenue - LAG(a.revenue) OVER (PARTITION BY a.c_region, a.p_category ORDER BY a.d_year))
        / NULLIF(LAG(a.revenue) OVER (PARTITION BY a.c_region, a.p_category ORDER BY a.d_year), 0) AS revenue_growth
FROM agg a
ORDER BY a.d_year, a.c_region, a.p_category
