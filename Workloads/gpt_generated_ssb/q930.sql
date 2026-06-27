WITH filtered_dates AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    d.d_year AS order_year,
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM filtered_dates d
JOIN lineorder lo
    ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
GROUP BY d.d_year, c.c_region, p.p_category, s.s_nation
ORDER BY total_profit DESC
LIMIT 100
