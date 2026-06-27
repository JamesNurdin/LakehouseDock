WITH base AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_custkey
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_shipmode = 'AIR'
),
agg AS (
    SELECT
        c_region,
        c_mktsegment,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_custkey) AS distinct_customers
    FROM base
    GROUP BY c_region, c_mktsegment
)
SELECT
    c_region,
    c_mktsegment,
    total_revenue,
    total_quantity,
    avg_discount,
    distinct_customers,
    total_revenue * 100.0 / SUM(total_revenue) OVER () AS revenue_pct
FROM agg
ORDER BY total_revenue DESC
LIMIT 10
