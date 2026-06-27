WITH order_dim AS (
    SELECT d_datekey, d_year, d_month
    FROM dim_date
),
commit_dim AS (
    SELECT d_datekey
    FROM dim_date
),
agg AS (
    SELECT
        od.d_year AS order_year,
        od.d_month AS order_month,
        p.p_category,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(*) AS order_line_count
    FROM lineorder lo
    JOIN order_dim od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN commit_dim cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
    GROUP BY od.d_year, od.d_month, p.p_category, s.s_region
)
SELECT
    order_year,
    order_month,
    p_category,
    s_region,
    total_revenue,
    total_supplycost,
    total_profit,
    order_line_count,
    RANK() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY order_year, profit_rank
LIMIT 10
