WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_shipmode,
        lo_orderpriority,
        lo_shippriority
    FROM lineorder
    WHERE lo_quantity > 10
      AND lo_discount < 5
)
SELECT
    s.s_region,
    p.p_category,
    sum(lo.lo_revenue) AS total_revenue,
    avg(lo.lo_discount) AS avg_discount,
    count(*) AS order_count,
    sum(lo.lo_extendedprice) - sum(lo.lo_supplycost * lo.lo_quantity) AS total_profit
FROM filtered_orders lo
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category IS NOT NULL
GROUP BY s.s_region, p.p_category
HAVING sum(lo.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
