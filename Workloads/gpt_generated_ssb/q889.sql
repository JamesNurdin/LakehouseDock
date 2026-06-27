WITH supplier_metrics AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        SUM(l.lo_revenue) AS total_revenue,
        SUM(l.lo_extendedprice - l.lo_supplycost) AS total_profit
    FROM lineorder AS l
    JOIN supplier AS s
        ON l.lo_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_region, s.s_nation
)
SELECT
    s_region,
    s_nation,
    s_name,
    total_revenue,
    total_profit,
    RANK() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS region_revenue_rank
FROM supplier_metrics
ORDER BY s_region, region_revenue_rank
