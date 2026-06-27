WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        s.s_region,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_supplycost) AS total_supplycost,
        sum(lo.lo_revenue) - sum(lo.lo_supplycost) AS profit,
        sum(lo.lo_quantity) AS total_quantity,
        avg(lo.lo_discount) AS avg_discount,
        count(distinct lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE s.s_region = 'ASIA'
      AND lo.lo_quantity > 10
      AND lo.lo_discount < 5
    GROUP BY c.c_region, p.p_category, s.s_region
)
SELECT
    c_region,
    p_category,
    s_region,
    total_revenue,
    total_supplycost,
    profit,
    total_quantity,
    avg_discount,
    order_count
FROM revenue_by_region_category
ORDER BY total_revenue DESC
LIMIT 20
