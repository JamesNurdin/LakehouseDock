WITH lo_metrics AS (
    SELECT
        lo_suppkey,
        lo_shipmode,
        lo_orderkey,
        lo_quantity,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
    WHERE lo_discount < 5
)
SELECT
    supplier.s_region,
    lo_metrics.lo_shipmode,
    sum(lo_metrics.lo_revenue) AS total_revenue,
    sum(lo_metrics.lo_supplycost) AS total_supplycost,
    sum(lo_metrics.lo_revenue) - sum(lo_metrics.lo_supplycost) AS total_profit,
    sum(lo_metrics.lo_quantity) AS total_quantity,
    avg(lo_metrics.lo_discount) AS avg_discount,
    count(DISTINCT lo_metrics.lo_orderkey) AS order_count
FROM lo_metrics
JOIN supplier
    ON lo_metrics.lo_suppkey = supplier.s_suppkey
GROUP BY supplier.s_region, lo_metrics.lo_shipmode
HAVING sum(lo_metrics.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100
