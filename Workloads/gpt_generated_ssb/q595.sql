WITH lo_agg AS (
    SELECT
        lo_partkey,
        SUM(lo_revenue) AS revenue_sum,
        SUM(lo_supplycost) AS supplycost_sum,
        SUM(lo_discount) AS discount_sum,
        COUNT(*) AS lineorder_cnt
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
    GROUP BY lo_partkey
)
SELECT
    p.p_category,
    p.p_brand1,
    SUM(lo_agg.revenue_sum) AS total_revenue,
    SUM(lo_agg.revenue_sum - lo_agg.supplycost_sum) AS total_profit,
    (SUM(lo_agg.discount_sum) * 1.0 / SUM(lo_agg.lineorder_cnt)) AS avg_discount,
    SUM(lo_agg.lineorder_cnt) AS total_lineorders,
    COUNT(DISTINCT lo_agg.lo_partkey) AS distinct_parts
FROM lo_agg
JOIN part p
    ON lo_agg.lo_partkey = p.p_partkey
WHERE p.p_category IN ('MFGR#12', 'MFGR#1')
GROUP BY p.p_category, p.p_brand1
HAVING SUM(lo_agg.revenue_sum) > 5000000
ORDER BY total_revenue DESC
LIMIT 10
