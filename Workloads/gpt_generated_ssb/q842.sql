WITH cust_sales AS (
    SELECT
        lo_custkey,
        SUM(lo_revenue) AS cust_total_revenue,
        SUM(lo_quantity) AS cust_total_quantity,
        AVG(lo_discount) AS cust_avg_discount,
        COUNT(*) AS cust_order_count
    FROM lineorder
    GROUP BY lo_custkey
)
SELECT
    c.c_region,
    c.c_mktsegment,
    SUM(cs.cust_total_revenue) AS region_total_revenue,
    SUM(cs.cust_total_quantity) AS region_total_quantity,
    AVG(cs.cust_avg_discount) AS region_avg_discount,
    COUNT(DISTINCT cs.lo_custkey) AS region_distinct_customers,
    COUNT(*) AS region_customer_count
FROM cust_sales cs
JOIN customer c
    ON cs.lo_custkey = c.c_custkey
WHERE c.c_region IN ('ASIA', 'EUROPE')
GROUP BY c.c_region, c.c_mktsegment
ORDER BY region_total_revenue DESC
LIMIT 10
