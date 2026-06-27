WITH customer_aggregates AS (
    SELECT
        c.c_custkey,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    GROUP BY
        c.c_custkey,
        c.c_region,
        c.c_nation,
        c.c_mktsegment
)
SELECT
    c_region,
    c_nation,
    c_mktsegment,
    SUM(total_revenue) AS sum_revenue,
    SUM(total_quantity) AS sum_quantity,
    AVG(avg_discount) AS avg_discount,
    SUM(order_count) AS total_orders
FROM customer_aggregates
GROUP BY
    c_region,
    c_nation,
    c_mktsegment
ORDER BY
    sum_revenue DESC
LIMIT 100
