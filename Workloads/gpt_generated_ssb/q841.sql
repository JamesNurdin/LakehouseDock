SELECT
    part.p_category,
    supplier.s_region,
    sum(lineorder.lo_revenue) AS total_revenue,
    sum(lineorder.lo_supplycost) AS total_supply_cost,
    sum(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    sum(lineorder.lo_quantity) AS total_quantity,
    count(DISTINCT lineorder.lo_orderkey) AS order_cnt
FROM lineorder
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE lineorder.lo_quantity > 20
  AND part.p_color = 'green'
GROUP BY
    part.p_category,
    supplier.s_region
ORDER BY total_revenue DESC
LIMIT 10
