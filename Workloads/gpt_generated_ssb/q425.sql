WITH lo_part_supplier AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        part.p_category,
        part.p_brand1,
        supplier.s_region,
        supplier.s_nation
    FROM lineorder lo
    JOIN part ON lo.lo_partkey = part.p_partkey
    JOIN supplier ON lo.lo_suppkey = supplier.s_suppkey
    WHERE lo.lo_discount BETWEEN 0 AND 10
      AND lo.lo_quantity >= 5
)
SELECT
    s_region,
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS line_count
FROM lo_part_supplier
GROUP BY s_region, p_category, p_brand1
ORDER BY total_profit DESC
LIMIT 10
