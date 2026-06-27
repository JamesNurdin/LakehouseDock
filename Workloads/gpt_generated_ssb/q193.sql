/*
  Analytical query on the SSB schema (Trino syntax)
  – Joins the four selected tables using the only allowed join keys.
  – Aggregates revenue, average discount and line‑item count per
    customer region, supplier region and part category.
*/
WITH lo_join AS (
    SELECT
        c.c_region      AS cust_region,
        s.s_region      AS supp_region,
        p.p_category    AS p_category,
        lo.lo_revenue,
        lo.lo_discount
    FROM lineorder lo
    JOIN customer c   ON lo.lo_custkey = c.c_custkey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    JOIN part p       ON lo.lo_partkey = p.p_partkey
    -- Example filter – keep only rows with a positive quantity
    WHERE lo.lo_quantity > 0
)
SELECT
    cust_region,
    supp_region,
    p_category,
    SUM(lo_revenue)      AS total_revenue,
    AVG(lo_discount)     AS avg_discount,
    COUNT(*)             AS lineitem_cnt
FROM lo_join
GROUP BY cust_region, supp_region, p_category
ORDER BY total_revenue DESC
LIMIT 50
