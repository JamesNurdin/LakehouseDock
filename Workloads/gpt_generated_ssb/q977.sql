SELECT
    p.p_category,
    s.s_region,
    AVG(date_diff('day', date(d_order.d_date), date(d_commit.d_date))) AS avg_lead_time_days,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1997'
GROUP BY p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 50
