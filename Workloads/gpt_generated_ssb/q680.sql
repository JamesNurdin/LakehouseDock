WITH lo_agg AS (
    SELECT
        lo_suppkey,
        lo_orderpriority,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_order_cnt
    FROM lineorder
    GROUP BY lo_suppkey, lo_orderpriority
)
SELECT
    s.s_region,
    s.s_nation,
    lo_agg.lo_orderpriority,
    lo_agg.total_revenue,
    lo_agg.total_quantity,
    lo_agg.avg_discount,
    lo_agg.distinct_order_cnt
FROM lo_agg
JOIN supplier s
    ON lo_agg.lo_suppkey = s.s_suppkey
WHERE s.s_region = 'AMERICA'
ORDER BY s.s_region, lo_agg.total_revenue DESC
