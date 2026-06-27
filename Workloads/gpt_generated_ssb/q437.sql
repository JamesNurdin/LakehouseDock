/*
  Revenue analysis by part category and brand for green parts with low discounts.
  The query joins lineorder and part, filters on discount and color, aggregates
  revenue, quantity and distinct orders, computes each group's share of total
  revenue, and ranks the groups by revenue.
*/
WITH part_revenue AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(l.lo_revenue) AS total_revenue,
        SUM(l.lo_quantity) AS total_quantity,
        COUNT(DISTINCT l.lo_orderkey) AS distinct_orders
    FROM lineorder l
    JOIN part p
        ON l.lo_partkey = p.p_partkey
    WHERE l.lo_discount BETWEEN 0 AND 10
      AND p.p_color = 'GREEN'
    GROUP BY p.p_category, p.p_brand1
),
grand_total AS (
    SELECT SUM(total_revenue) AS grand_total
    FROM part_revenue
)
SELECT
    pr.p_category,
    pr.p_brand1,
    pr.total_revenue,
    pr.total_quantity,
    pr.distinct_orders,
    (pr.total_revenue / NULLIF(gt.grand_total, 0)) * 100 AS revenue_pct_of_total,
    ROW_NUMBER() OVER (ORDER BY pr.total_revenue DESC) AS revenue_rank
FROM part_revenue pr
CROSS JOIN grand_total gt
ORDER BY pr.total_revenue DESC
LIMIT 10
