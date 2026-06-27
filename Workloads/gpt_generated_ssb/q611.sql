WITH filtered_orders AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost
    FROM lineorder lo
    WHERE lo.lo_revenue > 0
)
SELECT
    d.d_year,
    c.c_region,
    p.p_category,
    s.s_region,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM filtered_orders lo
JOIN dim_date d ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1997'
  AND p.p_size > 10
  AND s.s_region = 'ASIA'
GROUP BY d.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
