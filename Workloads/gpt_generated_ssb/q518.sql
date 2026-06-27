WITH lo_agg AS (
    SELECT
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_shipmode,
        SUM(lo.lo_revenue) AS revenue,
        SUM(lo.lo_supplycost) AS supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    WHERE lo.lo_quantity > 30
      AND lo.lo_discount < 5
    GROUP BY lo.lo_custkey, lo.lo_suppkey, lo.lo_shipmode
)
SELECT
    c.c_region,
    s.s_region,
    la.lo_shipmode,
    la.revenue,
    la.supply_cost,
    la.profit,
    la.total_quantity,
    la.avg_discount,
    la.profit / NULLIF(la.revenue, 0) AS profit_margin
FROM lo_agg la
JOIN customer c ON la.lo_custkey = c.c_custkey
JOIN supplier s ON la.lo_suppkey = s.s_suppkey
ORDER BY la.revenue DESC
LIMIT 100
