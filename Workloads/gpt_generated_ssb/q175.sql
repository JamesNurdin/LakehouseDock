WITH filtered_lineorder AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        p.p_category,
        p.p_brand1,
        p.p_type,
        p.p_color,
        p.p_size,
        p.p_container
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category IN ('MFGR#12', 'MFGR#1')
)
SELECT
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM filtered_lineorder
GROUP BY p_category, p_brand1
ORDER BY total_revenue DESC
LIMIT 10
