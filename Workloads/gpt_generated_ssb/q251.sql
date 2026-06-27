WITH category_region_sales AS (
    SELECT
        p.p_category,
        s.s_region,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_supplycost) AS total_supplycost,
        sum(lo.lo_quantity) AS total_quantity,
        avg(lo.lo_discount) AS avg_discount,
        count(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    GROUP BY p.p_category, s.s_region
)
SELECT
    p_category,
    s_region,
    total_revenue,
    total_supplycost,
    total_quantity,
    avg_discount,
    order_cnt,
    rank() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS revenue_rank_within_category
FROM category_region_sales
ORDER BY total_revenue DESC
LIMIT 50
