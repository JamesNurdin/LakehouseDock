SELECT
    od.d_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', DATE(od.d_date), DATE(cd.d_date))) AS avg_commit_delay,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date od
    ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
JOIN dim_date cd
    ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year BETWEEN '1995' AND '1996'
  AND cd.d_date > od.d_date
GROUP BY od.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
