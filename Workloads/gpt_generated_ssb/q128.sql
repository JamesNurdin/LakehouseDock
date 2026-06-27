SELECT
    s.s_region AS supplier_region,
    p.p_category AS product_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(date_diff('day', CAST(od_order.d_date AS date), CAST(od_commit.d_date AS date))) AS avg_lead_time_days,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date od_order
    ON lo.lo_orderdate = CAST(od_order.d_datekey AS integer)
JOIN dim_date od_commit
    ON lo.lo_commitdate = CAST(od_commit.d_datekey AS integer)
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
WHERE od_order.d_year = '1995'
  AND p.p_size > 10
  AND c.c_region = 'ASIA'
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 100
