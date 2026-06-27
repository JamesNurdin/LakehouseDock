WITH revenue_by_region AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        lo.lo_shipmode AS shipmode,
        SUM(lo.lo_revenue) AS shipmode_revenue,
        SUM(lo.lo_quantity) AS shipmode_quantity
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
    GROUP BY c.c_region, s.s_region, lo.lo_shipmode
)
SELECT
    customer_region,
    supplier_region,
    shipmode,
    shipmode_revenue,
    shipmode_quantity,
    shipmode_revenue * 1.0 / SUM(shipmode_revenue) OVER (PARTITION BY customer_region, supplier_region) AS revenue_share
FROM revenue_by_region
ORDER BY revenue_share DESC
LIMIT 20
