WITH order_dates AS (
    SELECT d_datekey
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit
FROM lineorder lo
JOIN order_dates od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
