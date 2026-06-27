/*
  Analytical query: revenue and supply‑cost performance per supplier city, with
  region‑level revenue share and city ranking within each region.
*/
WITH supplier_rev AS (
    SELECT
        s.s_region AS region,
        s.s_city   AS city,
        SUM(lo.lo_revenue)    AS revenue,
        SUM(lo.lo_supplycost) AS supply_cost,
        COUNT(*)              AS line_cnt
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 0
    GROUP BY s.s_region, s.s_city
)
SELECT
    region,
    city,
    revenue,
    supply_cost,
    line_cnt,
    revenue / SUM(revenue) OVER (PARTITION BY region) AS revenue_share_region,
    RANK() OVER (PARTITION BY region ORDER BY revenue DESC) AS city_revenue_rank
FROM supplier_rev
ORDER BY region, revenue DESC
LIMIT 50
