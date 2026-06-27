/*
  Star Schema Benchmark (SSB) analytical query
  • Shows revenue, profit and average order‑to‑commit lead time per
    customer region, supplier region, product category and year.
  • Joins all five selected tables using only the allowed join rules.
  • Filters to orders placed in 1997 and customers in the ASIA region.
*/
SELECT
    od.d_year AS order_year,
    cd.d_year AS commit_year,
    c.c_region,
    p.p_category,
    s.s_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.d_date AS date), CAST(cd.d_date AS date))) AS avg_lead_time_days,
    COUNT(DISTINCT lo.lo_custkey) AS distinct_customers
FROM lineorder lo
JOIN dim_date od
    ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd
    ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1997'
  AND c.c_region = 'ASIA'
GROUP BY od.d_year, cd.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 100
