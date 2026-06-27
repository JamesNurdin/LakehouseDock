WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_supplycost,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        c.c_region AS customer_region,
        c.c_nation AS customer_nation,
        p.p_brand1,
        p.p_category,
        p.p_size,
        s.s_nation AS supplier_nation
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'AMERICA' AND p.p_size > 10
)
SELECT
    supplier_nation,
    p_brand1,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM filtered_orders
GROUP BY
    supplier_nation,
    p_brand1,
    p_category
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_profit DESC
LIMIT 20
