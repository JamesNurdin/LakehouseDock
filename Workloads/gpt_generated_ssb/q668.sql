WITH lo_part AS (
    SELECT
        lo_orderkey,
        lo_partkey,
        lo_quantity,
        lo_revenue,
        lo_discount
    FROM lineorder
    WHERE lo_quantity > 0
)
SELECT
    part.p_category,
    part.p_brand1,
    SUM(lo_part.lo_revenue) AS total_revenue,
    SUM(lo_part.lo_quantity) AS total_quantity,
    AVG(lo_part.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_part.lo_orderkey) AS order_count
FROM lo_part
JOIN part
    ON lo_part.lo_partkey = part.p_partkey
WHERE part.p_size >= 10
  AND part.p_color = 'RED'
GROUP BY part.p_category, part.p_brand1
ORDER BY total_revenue DESC
LIMIT 100
