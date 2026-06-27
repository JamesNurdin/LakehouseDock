WITH revenue_by_customer AS (
    SELECT
        lo.lo_custkey,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    GROUP BY lo.lo_custkey
)
SELECT
    c.c_custkey,
    c.c_name,
    c.c_region,
    c.c_nation,
    c.c_mktsegment,
    rb.total_revenue,
    rb.avg_discount,
    rb.order_cnt
FROM revenue_by_customer rb
JOIN customer c
    ON rb.lo_custkey = c.c_custkey
WHERE c.c_region = 'ASIA'
ORDER BY rb.total_revenue DESC
LIMIT 10
