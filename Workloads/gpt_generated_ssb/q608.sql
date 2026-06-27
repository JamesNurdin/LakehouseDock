/*
  Top‑3 customers by revenue within each region for orders with quantity > 10
*/
WITH region_customer_revenue AS (
    SELECT
        customer.c_region,
        customer.c_custkey,
        customer.c_name,
        SUM(lineorder.lo_revenue) AS revenue
    FROM lineorder
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    WHERE lineorder.lo_quantity > 10
    GROUP BY customer.c_region, customer.c_custkey, customer.c_name
),
ranked_customers AS (
    SELECT
        c_region,
        c_custkey,
        c_name,
        revenue,
        rank() OVER (PARTITION BY c_region ORDER BY revenue DESC) AS region_rank
    FROM region_customer_revenue
)
SELECT
    c_region,
    c_custkey,
    c_name,
    revenue,
    region_rank
FROM ranked_customers
WHERE region_rank <= 3
ORDER BY c_region, region_rank
