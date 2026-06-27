WITH cust_rev AS (
    SELECT
        lo.lo_custkey,
        SUM(lo.lo_revenue) AS total_revenue,
        COUNT(*) AS order_cnt,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    WHERE lo.lo_quantity > 0
    GROUP BY lo.lo_custkey
)
SELECT
    c.c_custkey,
    c.c_name,
    c.c_region,
    c.c_mktsegment,
    cr.total_revenue,
    cr.order_cnt,
    cr.avg_discount
FROM cust_rev cr
JOIN customer c
    ON cr.lo_custkey = c.c_custkey
ORDER BY cr.total_revenue DESC
LIMIT 10
