WITH filtered_lo AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity
    FROM lineorder lo
    WHERE lo.lo_shipmode = 'AIR'
      AND lo.lo_orderpriority = '2-HIGH'
)
SELECT
    c.c_region,
    p.p_size,
    COUNT(DISTINCT filtered_lo.lo_orderkey) AS order_count,
    SUM(filtered_lo.lo_revenue) AS total_revenue,
    SUM(filtered_lo.lo_quantity) AS total_quantity,
    AVG(filtered_lo.lo_discount) AS avg_discount,
    (SUM(filtered_lo.lo_revenue) / NULLIF(SUM(filtered_lo.lo_quantity), 0)) AS revenue_per_quantity
FROM filtered_lo
JOIN customer c
    ON filtered_lo.lo_custkey = c.c_custkey
JOIN part p
    ON filtered_lo.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    p.p_size
ORDER BY total_revenue DESC
LIMIT 20
