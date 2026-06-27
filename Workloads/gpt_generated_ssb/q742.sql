WITH region_category_revenue AS (
    SELECT
        c.c_region AS c_region,
        p.p_category AS p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_discount BETWEEN 5 AND 20
      AND lo.lo_quantity > 5
      AND lo.lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY c.c_region, p.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_quantity,
    avg_discount,
    supplier_count,
    RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank_in_region
FROM region_category_revenue
ORDER BY c_region, revenue_rank_in_region
