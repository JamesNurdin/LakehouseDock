WITH order_dates AS (
    SELECT
        d_datekey,
        d_year
    FROM dim_date
    WHERE d_year BETWEEN '1995' AND '1997'
)
SELECT
    dd.d_year AS d_year,
    c.c_region AS c_region,
    p.p_category AS p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN order_dates dd ON CAST(dd.d_datekey AS integer) = lo.lo_orderdate
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
GROUP BY dd.d_year, c.c_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10
