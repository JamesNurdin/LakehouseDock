WITH revenue_by_brand AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS line_count
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity BETWEEN 1 AND 30
    GROUP BY p.p_category, p.p_brand1
)
SELECT
    rb.p_category,
    rb.p_brand1,
    rb.total_revenue,
    rb.avg_discount,
    rb.line_count,
    ROW_NUMBER() OVER (ORDER BY rb.total_revenue DESC) AS revenue_rank
FROM revenue_by_brand rb
WHERE rb.total_revenue > 0
ORDER BY rb.total_revenue DESC
LIMIT 10
