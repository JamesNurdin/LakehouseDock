WITH revenue_by_brand AS (
    SELECT 
        c.c_region AS cust_region,
        p.p_brand1 AS part_brand,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 30
      AND s.s_region = 'AMERICA'
    GROUP BY c.c_region, p.p_brand1
)
SELECT 
    cust_region,
    part_brand,
    total_revenue,
    total_supplycost,
    profit,
    RANK() OVER (PARTITION BY cust_region ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_brand
ORDER BY cust_region, revenue_rank
LIMIT 100
