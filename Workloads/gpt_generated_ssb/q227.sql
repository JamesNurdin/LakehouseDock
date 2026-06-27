WITH lo_ps AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        p.p_category,
        p.p_brand1,
        s.s_region
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderdate BETWEEN 19940101 AND 19940131
      AND lo.lo_quantity > 30
)
SELECT
    p_category,
    p_brand1,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lo_ps
GROUP BY p_category, p_brand1, s_region
ORDER BY total_profit DESC
LIMIT 100
