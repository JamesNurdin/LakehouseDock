WITH agg AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(l.lo_revenue) AS total_revenue,
        SUM(l.lo_quantity) AS total_quantity,
        AVG(l.lo_discount) AS avg_discount,
        COUNT(DISTINCT l.lo_orderkey) AS distinct_orders
    FROM lineorder AS l
    JOIN part AS p
        ON l.lo_partkey = p.p_partkey
    WHERE l.lo_shipmode = 'AIR'
    GROUP BY p.p_category, p.p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_quantity,
    avg_discount,
    distinct_orders,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 10
