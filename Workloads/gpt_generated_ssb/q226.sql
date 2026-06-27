WITH filtered_lo AS (
    SELECT
        lo_orderkey,
        lo_partkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_tax
    FROM lineorder
    WHERE lo_quantity > 30
      AND lo_discount BETWEEN 0 AND 5
),
part_info AS (
    SELECT
        p_partkey,
        p_category,
        p_brand1,
        p_color,
        p_type
    FROM part
    WHERE p_category = 'MFGR#12'
)
SELECT
    part_info.p_category,
    part_info.p_brand1,
    SUM(CAST(filtered_lo.lo_extendedprice AS double) * (1 - filtered_lo.lo_discount / 100.0)) AS revenue,
    AVG(filtered_lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT filtered_lo.lo_orderkey) AS order_count
FROM filtered_lo
JOIN part_info
  ON filtered_lo.lo_partkey = part_info.p_partkey
GROUP BY part_info.p_category, part_info.p_brand1
ORDER BY revenue DESC
LIMIT 10
