WITH revenue_by_region_category AS (
    SELECT
        s.s_region AS s_region,
        p.p_category AS p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 5
    GROUP BY s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    total_revenue,
    total_quantity,
    avg_discount,
    num_orders,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_category
ORDER BY total_revenue DESC
LIMIT 10
