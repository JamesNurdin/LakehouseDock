/*
  Revenue, profit and discount analysis by supplier region and part category.
  This query joins the lineorder fact table with part and supplier dimension tables
  using the only allowed join keys, aggregates key financial metrics, and orders
  the results by total profit.
*/
SELECT
    s.s_region AS region,
    p.p_category AS category,
    SUM(lo.lo_revenue)                AS total_revenue,
    SUM(lo.lo_supplycost)             AS total_supply_cost,
    SUM(lo.lo_tax)                    AS total_tax,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit,
    AVG(lo.lo_discount)               AS avg_discount,
    COUNT(*)                          AS order_count
FROM lineorder lo
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
HAVING SUM(lo.lo_revenue) > 0
ORDER BY total_profit DESC
LIMIT 20
