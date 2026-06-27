WITH part_agg AS (
    SELECT
        lo.lo_partkey,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_quantity) AS quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    WHERE lo.lo_quantity > 10
      AND lo.lo_discount BETWEEN 0 AND 5
    GROUP BY lo.lo_partkey
)
SELECT
    p.p_category,
    p.p_brand1,
    part_agg.revenue,
    part_agg.quantity,
    part_agg.avg_discount
FROM part_agg
JOIN part p
    ON part_agg.lo_partkey = p.p_partkey
ORDER BY part_agg.revenue DESC
LIMIT 50
