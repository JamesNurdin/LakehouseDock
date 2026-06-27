WITH customer_supplier_revenue AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region AS customer_region,
        s.s_suppkey,
        s.s_name,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
    GROUP BY
        c.c_custkey,
        c.c_name,
        c.c_region,
        s.s_suppkey,
        s.s_name,
        s.s_region
)
SELECT
    c_custkey,
    c_name,
    customer_region,
    s_suppkey,
    s_name,
    supplier_region,
    total_revenue,
    total_profit,
    order_count,
    RANK() OVER (PARTITION BY customer_region ORDER BY total_revenue DESC) AS revenue_rank_in_region
FROM customer_supplier_revenue
ORDER BY customer_region, revenue_rank_in_region
LIMIT 20
