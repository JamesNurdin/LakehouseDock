/*
  Revenue and quantity per supplier region and nation, with the average revenue per region.
  Uses only the lineorder and supplier tables and follows the allowed join rule.
*/
WITH supplier_revenue AS (
    SELECT
        s.s_suppkey,
        s.s_region,
        s.s_nation,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        COUNT(*) AS line_count
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 30
      AND lo.lo_discount < 5
    GROUP BY s.s_suppkey, s.s_region, s.s_nation
)
SELECT
    sr.s_region,
    sr.s_nation,
    sr.total_revenue,
    sr.total_quantity,
    sr.line_count,
    AVG(sr.total_revenue) OVER (PARTITION BY sr.s_region) AS avg_region_revenue
FROM supplier_revenue sr
ORDER BY sr.total_revenue DESC
LIMIT 50
