WITH lo_agg AS (
    SELECT
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'ASIA'
    GROUP BY s.s_region, p.p_category
    HAVING SUM(lo.lo_revenue - lo.lo_supplycost) > 1000000
)
SELECT
    supplier_region,
    part_category,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY supplier_region ORDER BY total_profit DESC) AS profit_rank
FROM lo_agg
ORDER BY total_profit DESC
LIMIT 10
