WITH filtered_lo AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_revenue,
        lo_discount,
        lo_orderpriority,
        lo_shipmode
    FROM lineorder
    WHERE lo_discount BETWEEN 0 AND 5
      AND lo_orderpriority = '1-URGENT'
)
SELECT
    c.c_region,
    p.p_category,
    SUM(filtered_lo.lo_revenue) AS total_revenue,
    AVG(filtered_lo.lo_discount) AS avg_discount,
    COUNT(*) AS order_cnt,
    COUNT(DISTINCT filtered_lo.lo_orderkey) AS distinct_orders
FROM filtered_lo
JOIN customer c ON filtered_lo.lo_custkey = c.c_custkey
JOIN part p ON filtered_lo.lo_partkey = p.p_partkey
GROUP BY c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
