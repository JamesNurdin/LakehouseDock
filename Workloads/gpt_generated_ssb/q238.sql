WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_tax
    FROM lineorder lo
    WHERE lo.lo_shipmode = 'AIR'
      AND lo.lo_orderpriority = '1-URGENT'
)
SELECT
    s.s_region,
    p.p_category,
    sum(f.lo_revenue) AS total_revenue,
    sum(f.lo_quantity) AS total_quantity,
    avg(f.lo_discount) AS avg_discount,
    sum(f.lo_revenue - f.lo_supplycost - f.lo_tax) AS total_profit,
    count(DISTINCT f.lo_orderkey) AS distinct_orders
FROM filtered_orders f
JOIN part p ON f.lo_partkey = p.p_partkey
JOIN supplier s ON f.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
