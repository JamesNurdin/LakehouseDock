WITH lo_filtered AS (
    SELECT
        lo_custkey,
        lo_quantity,
        lo_revenue,
        lo_discount
    FROM lineorder
    WHERE lo_quantity > 5
)
SELECT
    c.c_region,
    c.c_nation,
    CASE WHEN lo_filtered.lo_discount < 3 THEN 'Low' ELSE 'High' END AS discount_category,
    SUM(lo_filtered.lo_revenue) AS total_revenue,
    AVG(lo_filtered.lo_quantity) AS avg_quantity,
    COUNT(DISTINCT lo_filtered.lo_custkey) AS distinct_customers
FROM lo_filtered
JOIN customer c
    ON lo_filtered.lo_custkey = c.c_custkey
GROUP BY
    c.c_region,
    c.c_nation,
    CASE WHEN lo_filtered.lo_discount < 3 THEN 'Low' ELSE 'High' END
HAVING
    SUM(lo_filtered.lo_revenue) > 500000
ORDER BY
    total_revenue DESC
LIMIT 20
