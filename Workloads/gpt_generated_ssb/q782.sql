WITH order_dates AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year BETWEEN '1992' AND '1997'
),
yearly_revenue AS (
    SELECT
        od.d_year,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue
    FROM lineorder lo
    JOIN order_dates od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'AMERICA'
      AND p.p_category = 'MFGR#1'
    GROUP BY od.d_year, s.s_region
)
SELECT
    yr.d_year AS order_year,
    yr.s_region,
    yr.total_revenue,
    SUM(yr.total_revenue) OVER (PARTITION BY yr.s_region ORDER BY yr.d_year) AS cumulative_revenue
FROM yearly_revenue yr
ORDER BY yr.d_year, yr.s_region
