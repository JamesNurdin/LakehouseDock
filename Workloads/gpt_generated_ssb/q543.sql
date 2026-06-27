WITH revenue_by_supplier AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        lo.lo_orderpriority,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    GROUP BY
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        lo.lo_orderpriority
)
SELECT
    rbs.s_region,
    rbs.s_nation,
    rbs.lo_orderpriority,
    rbs.s_name,
    rbs.total_revenue,
    rbs.total_profit,
    rbs.order_count,
    RANK() OVER (PARTITION BY rbs.s_region ORDER BY rbs.total_revenue DESC) AS revenue_rank_in_region
FROM revenue_by_supplier rbs
ORDER BY
    rbs.s_region,
    revenue_rank_in_region,
    rbs.total_revenue DESC
