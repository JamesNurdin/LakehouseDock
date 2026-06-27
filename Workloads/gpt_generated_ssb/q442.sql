WITH revenue_by_region AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_quantity) AS total_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND lo.lo_shipmode = 'AIR'
    GROUP BY
        c.c_region,
        s.s_region
)
SELECT
    customer_region,
    supplier_region,
    total_revenue,
    total_extendedprice,
    total_supplycost,
    total_quantity,
    order_count,
    avg_discount,
    (total_revenue - total_supplycost) AS profit
FROM revenue_by_region
ORDER BY total_revenue DESC
LIMIT 100
