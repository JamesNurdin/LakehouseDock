WITH order_dates AS (
    SELECT d_datekey,
           d_year,
           d_date
    FROM dim_date
    WHERE CAST(d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    od.d_year,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN order_dates od
    ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12'
GROUP BY od.d_year, s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10
