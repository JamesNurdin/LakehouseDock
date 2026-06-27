WITH cust_rev AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_quantity > 10
    GROUP BY c.c_custkey, c.c_name, c.c_region, c.c_mktsegment
)
SELECT
    c_custkey,
    c_name,
    c_region,
    c_mktsegment,
    total_revenue,
    total_quantity,
    avg_discount
FROM cust_rev
ORDER BY total_revenue DESC
LIMIT 10
