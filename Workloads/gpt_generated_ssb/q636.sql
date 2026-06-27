WITH agg AS (
    SELECT
        od.d_year AS d_year,
        c.c_region AS c_region,
        p.p_category AS p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(date_diff('day', CAST(od.d_date AS DATE), CAST(cd.d_date AS DATE))) AS avg_lead_time_days
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
    GROUP BY od.d_year, c.c_region, p.p_category
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue,
    total_profit,
    avg_lead_time_days,
    rank() OVER (PARTITION BY d_year, c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
WHERE total_revenue > 1000000
ORDER BY d_year, c_region, revenue_rank
