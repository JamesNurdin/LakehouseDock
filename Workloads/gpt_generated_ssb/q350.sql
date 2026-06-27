SELECT
    d.d_year,
    c.c_region,
    p.p_category,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    count(*) AS order_count,
    avg(lo.lo_discount) AS avg_discount,
    sum(lo.lo_supplycost) AS total_supply_cost
FROM lineorder lo
JOIN dim_date d
  ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
  AND c.c_region = 'AMERICA'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
