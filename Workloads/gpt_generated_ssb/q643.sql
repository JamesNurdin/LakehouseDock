WITH filtered_lo AS (
    SELECT
        lo_partkey,
        lo_revenue,
        lo_supplycost,
        lo_shipmode,
        lo_quantity,
        lo_discount
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
      AND lo_quantity BETWEEN 1 AND 30
      AND lo_discount > 0
)
SELECT
    part.p_category,
    part.p_brand1,
    SUM(filtered_lo.lo_revenue) AS total_revenue,
    SUM(filtered_lo.lo_revenue - filtered_lo.lo_supplycost) AS total_profit,
    COUNT(*) AS order_count,
    AVG(filtered_lo.lo_discount) AS avg_discount
FROM filtered_lo
JOIN part
    ON filtered_lo.lo_partkey = part.p_partkey
GROUP BY part.p_category, part.p_brand1
ORDER BY total_revenue DESC
LIMIT 10
