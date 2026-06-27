WITH order_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
),
commit_date AS (
    SELECT d_datekey, d_year AS commit_year
    FROM dim_date
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    od.d_year AS order_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    AVG(CAST(cd.d_datekey AS integer) - CAST(od.d_datekey AS integer)) AS avg_commit_delay_days
FROM lineorder lo
JOIN order_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN commit_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#1'
  AND CAST(od.d_year AS integer) BETWEEN 1995 AND 1997
GROUP BY
    c.c_region,
    s.s_region,
    od.d_year
ORDER BY total_revenue DESC
LIMIT 10
