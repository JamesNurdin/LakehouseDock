WITH revenue_by_region_category AS (
    SELECT
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    total_revenue,
    total_supply_cost,
    total_profit,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_category
ORDER BY total_revenue DESC
