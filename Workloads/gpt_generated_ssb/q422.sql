WITH part_filtered AS (
    SELECT
        p_partkey,
        p_category,
        p_brand1,
        p_color,
        p_size
    FROM part
    WHERE p_category = 'MFGR#12'
      AND p_size BETWEEN 10 AND 20
),
order_agg AS (
    SELECT
        lo_partkey,
        SUM(lo_revenue) AS revenue,
        SUM(lo_extendedprice * lo_discount / 100) AS discount_amount,
        AVG(lo_discount) AS avg_discount,
        SUM(lo_quantity) AS total_quantity
    FROM lineorder
    WHERE lo_quantity > 0
    GROUP BY lo_partkey
)
SELECT
    pf.p_category,
    pf.p_brand1,
    oa.revenue,
    oa.discount_amount,
    oa.avg_discount,
    oa.total_quantity
FROM order_agg oa
JOIN part_filtered pf
  ON oa.lo_partkey = pf.p_partkey
ORDER BY oa.revenue DESC
LIMIT 20
