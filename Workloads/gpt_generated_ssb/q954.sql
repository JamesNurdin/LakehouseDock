WITH cust_rev AS (
    SELECT
        customer.c_custkey,
        customer.c_name,
        customer.c_region,
        customer.c_mktsegment,
        SUM(lineorder.lo_revenue) AS total_revenue,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(DISTINCT lineorder.lo_orderkey) AS order_cnt,
        SUM(lineorder.lo_quantity) AS total_quantity
    FROM lineorder
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    GROUP BY
        customer.c_custkey,
        customer.c_name,
        customer.c_region,
        customer.c_mktsegment
),
ranked_cust AS (
    SELECT
        c_custkey,
        c_name,
        c_region,
        c_mktsegment,
        total_revenue,
        avg_discount,
        order_cnt,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_rank
    FROM cust_rev
)
SELECT
    c_custkey,
    c_name,
    c_region,
    c_mktsegment,
    total_revenue,
    avg_discount,
    order_cnt,
    total_quantity
FROM ranked_cust
WHERE region_rank <= 5
ORDER BY c_region, total_revenue DESC
