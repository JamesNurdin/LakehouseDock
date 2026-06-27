WITH profit_by_region_category AS (
    SELECT
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category IN ('MFGR#1', 'MFGR#2')
    GROUP BY c.c_region, s.s_region, p.p_category
)
SELECT
    cust_region,
    supp_region,
    p_category,
    total_revenue,
    total_supplycost,
    profit,
    avg_discount,
    order_cnt
FROM profit_by_region_category
ORDER BY profit DESC
LIMIT 10
