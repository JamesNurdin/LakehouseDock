WITH cust_revenue AS (
    SELECT
        lo_custkey,
        SUM(lo_revenue) AS cust_revenue,
        COUNT(*) AS order_cnt
    FROM lineorder
    GROUP BY lo_custkey
),
ranked_customers AS (
    SELECT
        customer.c_region,
        customer.c_nation,
        customer.c_mktsegment,
        customer.c_name,
        cust_revenue.cust_revenue,
        cust_revenue.order_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY customer.c_region, customer.c_mktsegment
            ORDER BY cust_revenue.cust_revenue DESC
        ) AS revenue_rank
    FROM cust_revenue
    JOIN customer
        ON cust_revenue.lo_custkey = customer.c_custkey
    WHERE cust_revenue.cust_revenue > 0
)
SELECT
    c_region,
    c_nation,
    c_mktsegment,
    c_name,
    cust_revenue,
    order_cnt,
    revenue_rank
FROM ranked_customers
WHERE revenue_rank <= 3
ORDER BY c_region, c_mktsegment, revenue_rank
