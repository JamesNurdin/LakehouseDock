WITH lo_detail AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        p.p_category AS p_category,
        p.p_brand1 AS p_brand1
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE c.c_region = 'ASIA'
      AND s.s_region = 'ASIA'
)
SELECT
    cust_region,
    supp_region,
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(DISTINCT lo_custkey) AS distinct_customers
FROM lo_detail
GROUP BY cust_region, supp_region, p_category, p_brand1
ORDER BY total_profit DESC
LIMIT 10
