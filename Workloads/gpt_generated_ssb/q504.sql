/*
   Revenue by customer region and part category with ranking
   – joins lineorder, customer and part using the only allowed keys
   – filters to two regions and excludes empty categories
   – aggregates revenue and distinct order count per region‑category pair
   – keeps only groups with more than 1 000 000 revenue
   – ranks the resulting rows by total revenue
*/
WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE c.c_region IN ('AMERICA', 'EUROPE')
      AND p.p_category IS NOT NULL
    GROUP BY c.c_region, p.p_category
    HAVING SUM(lo.lo_revenue) > 1000000
)
SELECT
    c_region,
    p_category,
    total_revenue,
    order_cnt,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_category
ORDER BY revenue_rank
