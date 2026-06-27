WITH date_1995 AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1995'
),
part_mfgr1 AS (
    SELECT p_partkey
    FROM part
    WHERE p_category = 'MFGR#1'
)
SELECT
    d.d_year,
    s.s_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
FROM lineorder lo
JOIN date_1995 d
    ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN part_mfgr1 p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
GROUP BY d.d_year, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
