WITH revenue_by_region AS (
    SELECT
        customer.c_region,
        customer.c_mktsegment,
        lineorder.lo_orderpriority,
        sum(lineorder.lo_revenue) AS total_revenue,
        sum(lineorder.lo_discount) AS total_discount,
        avg(lineorder.lo_discount) AS avg_discount,
        sum(lineorder.lo_quantity) AS total_quantity,
        count(DISTINCT lineorder.lo_orderkey) AS order_count
    FROM lineorder
    JOIN customer ON lineorder.lo_custkey = customer.c_custkey
    WHERE lineorder.lo_quantity > 10
      AND lineorder.lo_discount < 5
    GROUP BY customer.c_region, customer.c_mktsegment, lineorder.lo_orderpriority
)
SELECT
    c_region,
    c_mktsegment,
    lo_orderpriority,
    total_revenue,
    total_discount,
    avg_discount,
    total_quantity,
    order_count,
    rank() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region
WHERE total_revenue > 1000000
ORDER BY total_revenue DESC
