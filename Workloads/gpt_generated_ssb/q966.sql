WITH revenue_by_region_category AS (
    SELECT
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    GROUP BY s.s_region, p.p_category
),
ranked AS (
    SELECT
        supplier_region,
        part_category,
        total_revenue,
        total_quantity,
        avg_discount,
        order_cnt,
        total_revenue * 1.0 / SUM(total_revenue) OVER (PARTITION BY supplier_region) AS revenue_share,
        ROW_NUMBER() OVER (PARTITION BY supplier_region ORDER BY total_revenue DESC) AS region_rank
    FROM revenue_by_region_category
)
SELECT
    supplier_region,
    part_category,
    total_revenue,
    total_quantity,
    avg_discount,
    order_cnt,
    revenue_share,
    region_rank
FROM ranked
WHERE region_rank <= 5
ORDER BY supplier_region, region_rank
