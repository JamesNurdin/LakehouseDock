WITH cust_revenue AS (
    SELECT
        customer.c_custkey,
        customer.c_name,
        customer.c_region,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    WHERE lineorder.lo_quantity > 30
    GROUP BY
        customer.c_custkey,
        customer.c_name,
        customer.c_region
),
ranked AS (
    SELECT
        cust_revenue.c_custkey,
        cust_revenue.c_name,
        cust_revenue.c_region,
        cust_revenue.total_revenue,
        cust_revenue.total_profit,
        cust_revenue.avg_discount,
        cust_revenue.order_count,
        ROW_NUMBER() OVER (PARTITION BY cust_revenue.c_region ORDER BY cust_revenue.total_revenue DESC) AS region_rank
    FROM cust_revenue
)
SELECT
    ranked.c_custkey,
    ranked.c_name,
    ranked.c_region,
    ranked.total_revenue,
    ranked.total_profit,
    ranked.avg_discount,
    ranked.order_count,
    ranked.region_rank
FROM ranked
WHERE ranked.region_rank <= 5
ORDER BY ranked.c_region, ranked.region_rank
