WITH lo_part AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_shipmode,
        p.p_category,
        p.p_brand1,
        p.p_color,
        p.p_size
    FROM lineorder lo
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity > 10
      AND p.p_size >= 20
)
SELECT
    p_category,
    p_brand1,
    lo_shipmode,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS line_count
FROM lo_part
GROUP BY p_category, p_brand1, lo_shipmode
ORDER BY total_revenue DESC
LIMIT 50
