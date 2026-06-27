WITH revenue_by_part AS (
    SELECT
        lo.lo_partkey,
        SUM(lo.lo_revenue) AS revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    WHERE lo.lo_quantity >= 20
      AND lo.lo_discount <= 10
    GROUP BY lo.lo_partkey
)
SELECT
    p.p_category,
    p.p_brand1,
    SUM(r.revenue) AS total_revenue,
    AVG(r.avg_discount) AS overall_avg_discount,
    SUM(r.order_cnt) AS total_orders,
    RANK() OVER (ORDER BY SUM(r.revenue) DESC) AS revenue_rank
FROM revenue_by_part r
JOIN part p ON r.lo_partkey = p.p_partkey
GROUP BY p.p_category, p.p_brand1
ORDER BY total_revenue DESC
LIMIT 10
