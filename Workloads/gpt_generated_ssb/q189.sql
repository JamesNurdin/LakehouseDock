WITH order_profit AS (
    SELECT
        lo_partkey,
        lo_extendedprice,
        lo_quantity,
        lo_discount,
        lo_supplycost,
        (lo_extendedprice * (1 - CAST(lo_discount AS DOUBLE) / 100) - lo_supplycost * lo_quantity) AS profit
    FROM lineorder
    WHERE lo_quantity > 0
)
SELECT
    p.p_category,
    p.p_brand1,
    SUM(op.profit) AS total_profit,
    COUNT(*) AS order_line_count,
    AVG(op.profit) AS avg_profit_per_line
FROM order_profit op
JOIN part p
    ON op.lo_partkey = p.p_partkey
GROUP BY p.p_category, p.p_brand1
ORDER BY total_profit DESC
LIMIT 10
