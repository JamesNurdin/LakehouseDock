WITH grouped AS (
    SELECT
        c.c_region,
        p.p_category,
        s.s_nation,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'ASIA'
      AND p.p_category = 'MFGR#1'
      AND s.s_nation = 'CHINA'
    GROUP BY c.c_region, p.p_category, s.s_nation
)
SELECT
    c_region,
    p_category,
    s_nation,
    total_revenue,
    total_profit,
    total_quantity,
    avg_discount,
    order_cnt,
    total_revenue * 100.0 / SUM(total_revenue) OVER () AS revenue_pct
FROM grouped
ORDER BY total_profit DESC
LIMIT 10
