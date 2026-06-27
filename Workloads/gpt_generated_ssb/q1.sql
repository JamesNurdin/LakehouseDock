WITH filtered_lineorder AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_suppkey,
        lo_orderdate,
        lo_orderpriority,
        lo_quantity,
        lo_discount,
        lo_revenue
    FROM lineorder
    WHERE lo_orderdate BETWEEN 19940101 AND 19941231
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    fo.lo_orderpriority AS order_priority,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_quantity) AS total_quantity,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_orderkey) AS order_count
FROM filtered_lineorder fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    s.s_region,
    fo.lo_orderpriority
HAVING SUM(fo.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
