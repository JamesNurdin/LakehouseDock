WITH lo_calc AS (
    SELECT
        lo_custkey,
        lo_suppkey,
        lo_partkey,
        lo_orderpriority,
        lo_extendedprice,
        lo_discount,
        lo_supplycost,
        lo_quantity,
        (lo_extendedprice * (1 - lo_discount / 100.0)) AS revenue,
        ((lo_extendedprice * (1 - lo_discount / 100.0)) - lo_supplycost * lo_quantity) AS profit
    FROM lineorder
)
SELECT
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.revenue) AS total_revenue,
    SUM(lo.profit) AS total_profit,
    COUNT(*) AS order_count
FROM lo_calc lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN part p ON lo.lo_partkey = p.p_partkey
WHERE lo.lo_orderpriority = '1-URGENT'
GROUP BY c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
