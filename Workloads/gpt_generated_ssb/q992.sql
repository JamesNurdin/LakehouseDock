WITH region_category_stats AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_size BETWEEN 10 AND 20
    GROUP BY c.c_region, p.p_category
    HAVING SUM(lo.lo_revenue) > 500000
),
ranked_stats AS (
    SELECT
        c_region,
        p_category,
        total_revenue,
        total_supply_cost,
        total_revenue - total_supply_cost AS profit,
        CAST(total_revenue - total_supply_cost AS DOUBLE) / total_revenue AS profit_margin,
        order_cnt,
        RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM region_category_stats
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_supply_cost,
    profit,
    profit_margin,
    order_cnt,
    revenue_rank
FROM ranked_stats
WHERE revenue_rank <= 3
ORDER BY c_region, revenue_rank
