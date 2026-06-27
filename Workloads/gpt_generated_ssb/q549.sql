WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        s.s_nation,
        lo.lo_orderdate,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_brand1 = 'Brand#45'
      AND s.s_region = 'ASIA'
    GROUP BY c.c_region, p.p_category, s.s_nation, lo.lo_orderdate
)
SELECT
    c_region,
    p_category,
    s_nation,
    lo_orderdate,
    total_revenue,
    avg_discount,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_rank
FROM revenue_by_region_category
ORDER BY total_revenue DESC
LIMIT 100
