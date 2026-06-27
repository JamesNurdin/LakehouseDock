WITH supplier_agg AS (
    SELECT
        lo.lo_suppkey AS lo_suppkey,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    WHERE lo.lo_shipmode IN ('AIR', 'RAIL')
    GROUP BY lo.lo_suppkey
)
SELECT
    s.s_region,
    s.s_nation,
    SUM(sa.total_revenue) AS region_total_revenue,
    SUM(sa.total_quantity) AS region_total_quantity,
    AVG(sa.avg_discount) AS region_avg_discount,
    SUM(sa.order_count) AS region_order_count,
    SUM(sa.total_revenue) / NULLIF(SUM(sa.total_quantity), 0) AS revenue_per_quantity
FROM supplier_agg sa
JOIN supplier s
    ON sa.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, s.s_nation
ORDER BY region_total_revenue DESC
LIMIT 20
