WITH lo_agg AS (
    SELECT
        lo_suppkey,
        lo_shipmode,
        SUM(lo_revenue) AS revenue_sum,
        SUM(lo_supplycost) AS supplycost_sum,
        SUM(lo_extendedprice) AS extendedprice_sum,
        AVG(lo_discount) AS discount_avg,
        COUNT(*) AS order_count
    FROM lineorder
    GROUP BY lo_suppkey, lo_shipmode
)
SELECT
    s.s_region,
    lo_agg.lo_shipmode,
    lo_agg.revenue_sum,
    lo_agg.supplycost_sum,
    lo_agg.revenue_sum - lo_agg.supplycost_sum AS profit,
    lo_agg.extendedprice_sum,
    lo_agg.discount_avg,
    lo_agg.order_count,
    RANK() OVER (PARTITION BY s.s_region ORDER BY lo_agg.revenue_sum DESC) AS revenue_rank
FROM lo_agg
JOIN supplier s
    ON lo_agg.lo_suppkey = s.s_suppkey
ORDER BY s.s_region, lo_agg.revenue_sum DESC
