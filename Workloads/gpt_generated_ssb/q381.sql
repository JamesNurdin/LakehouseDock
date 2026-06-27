WITH revenue_by_region_category AS (
    SELECT
        s.s_region AS s_region,
        p.p_category AS p_category,
        SUM(lo.lo_extendedprice * (100 - lo.lo_discount) / 100) AS revenue,
        COUNT(*) AS order_cnt,
        AVG(lo.lo_quantity) AS avg_quantity
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_discount BETWEEN 5 AND 10
      AND lo.lo_quantity > 20
      AND lo.lo_orderpriority = '1-URGENT'
    GROUP BY s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    revenue,
    order_cnt,
    avg_quantity,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    SUM(revenue) OVER (
        PARTITION BY s_region
        ORDER BY revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_by_region
FROM revenue_by_region_category
ORDER BY revenue DESC
LIMIT 20
