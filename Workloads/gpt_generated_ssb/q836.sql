WITH aggregated AS (
    SELECT
        c.c_region,
        s.s_region,
        d.d_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS lineitem_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year = '1997'
      AND p.p_category = 'MFGR#12'
      AND s.s_region = 'ASIA'
    GROUP BY c.c_region, s.s_region, d.d_year, p.p_category
)
SELECT
    c_region,
    s_region,
    d_year,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    lineitem_count,
    RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 10
