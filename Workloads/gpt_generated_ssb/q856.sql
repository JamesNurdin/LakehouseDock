WITH revenue_by_customer AS (
    SELECT
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        lo.lo_custkey,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_discount BETWEEN 0 AND 10
    GROUP BY c.c_region, c.c_nation, c.c_mktsegment, lo.lo_custkey
    HAVING SUM(lo.lo_revenue) > 1000000
)
SELECT
    c_region AS region,
    c_nation AS nation,
    c_mktsegment AS market_segment,
    total_revenue,
    total_quantity,
    avg_discount,
    order_count
FROM revenue_by_customer
ORDER BY total_revenue DESC
LIMIT 20
