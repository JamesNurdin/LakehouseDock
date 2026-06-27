WITH supplier_profit AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
    GROUP BY s.s_suppkey, s.s_name, s.s_region, s.s_nation
)
SELECT
    s_name,
    s_region,
    s_nation,
    total_profit,
    total_quantity,
    avg_discount,
    order_count
FROM supplier_profit
ORDER BY total_profit DESC
LIMIT 5
