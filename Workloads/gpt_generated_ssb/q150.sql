WITH supplier_part_revenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) - lo.lo_supplycost * lo.lo_quantity) AS profit,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    s_name,
    revenue,
    profit,
    order_cnt,
    RANK() OVER (PARTITION BY s_region ORDER BY revenue DESC) AS revenue_rank
FROM supplier_part_revenue
ORDER BY s_region, revenue_rank
