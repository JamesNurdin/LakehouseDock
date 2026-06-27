WITH profit_by_year_region AS (
    SELECT
        od.d_year AS year,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#1'
    GROUP BY od.d_year, s.s_region, p.p_category
)
SELECT
    year,
    supplier_region,
    part_category,
    revenue,
    profit,
    order_count,
    RANK() OVER (PARTITION BY year ORDER BY profit DESC) AS profit_rank
FROM profit_by_year_region
ORDER BY year, profit_rank
LIMIT 20
