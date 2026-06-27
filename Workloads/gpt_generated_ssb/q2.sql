WITH lo_part AS (
    SELECT
        lo_partkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_shipmode
    FROM lineorder
    WHERE lo_quantity > 10
),
part_info AS (
    SELECT
        p_partkey,
        p_category,
        p_brand1,
        p_color,
        p_size
    FROM part
    WHERE p_category IN ('MFGR#12', 'MFGR#13')
)
SELECT
    pi.p_category,
    pi.p_brand1,
    pi.p_color,
    SUM(lp.lo_extendedprice * (1 - lp.lo_discount)) AS total_sales,
    SUM(lp.lo_revenue) AS total_revenue,
    SUM(lp.lo_supplycost) AS total_supply_cost,
    SUM(lp.lo_revenue - lp.lo_supplycost) AS total_profit,
    AVG(lp.lo_discount) AS avg_discount,
    COUNT(*) AS order_lines
FROM lo_part lp
JOIN part_info pi
    ON lp.lo_partkey = pi.p_partkey
GROUP BY pi.p_category, pi.p_brand1, pi.p_color
ORDER BY total_profit DESC
LIMIT 100
