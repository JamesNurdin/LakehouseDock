WITH supplier_profit AS (
    SELECT
        sup.s_suppkey,
        sup.s_name,
        sup.s_nation,
        sup.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN supplier sup ON lo.lo_suppkey = sup.s_suppkey
    WHERE lo.lo_orderpriority = '1-URGENT'
    GROUP BY sup.s_suppkey, sup.s_name, sup.s_nation, sup.s_region
)
SELECT
    sp.s_name,
    sp.s_nation,
    sp.s_region,
    sp.total_revenue,
    sp.total_supplycost,
    sp.profit
FROM supplier_profit sp
ORDER BY sp.profit DESC
LIMIT 10
