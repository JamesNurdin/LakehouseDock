WITH revenue_by_supplier_part AS (
    SELECT
        s.s_region AS s_region,
        p.p_category AS p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
        COUNT(*) AS line_cnt
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 5
    GROUP BY s.s_region, p.p_category
)
SELECT
    s_region,
    p_category,
    total_revenue,
    total_supplycost,
    profit,
    avg_discount,
    order_cnt,
    line_cnt,
    RANK() OVER (ORDER BY profit DESC) AS profit_rank
FROM revenue_by_supplier_part
ORDER BY profit_rank
LIMIT 20
