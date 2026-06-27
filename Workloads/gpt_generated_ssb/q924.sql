WITH agg_by_region_category AS (
    SELECT
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS line_item_cnt
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR' AND lo.lo_orderpriority = '1-URGENT'
    GROUP BY s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    line_item_cnt,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg_by_region_category
ORDER BY profit_rank
