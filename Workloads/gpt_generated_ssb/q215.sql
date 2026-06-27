WITH profit_by_region AS (
    SELECT
        c.c_region,
        s.s_region,
        d.d_year,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE p.p_category = 'MFGR#1'
      AND lo.lo_discount > 5
      AND d.d_year BETWEEN '1994' AND '1995'
    GROUP BY c.c_region, s.s_region, d.d_year
)
SELECT
    c_region,
    s_region,
    d_year,
    total_revenue,
    total_profit,
    RANK() OVER (PARTITION BY c_region, d_year ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_region
ORDER BY c_region, d_year, profit_rank
LIMIT 100
