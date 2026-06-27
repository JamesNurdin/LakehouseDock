SELECT
    customer.c_region,
    supplier.s_region,
    part.p_category,
    year(CAST(dim_date.d_date AS date)) AS order_year,
    sum(lineorder.lo_revenue) AS total_revenue,
    sum(lineorder.lo_supplycost) AS total_supply_cost,
    sum(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit
FROM lineorder
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN dim_date
    ON CAST(lineorder.lo_orderdate AS varchar) = dim_date.d_datekey
WHERE CAST(dim_date.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY
    customer.c_region,
    supplier.s_region,
    part.p_category,
    year(CAST(dim_date.d_date AS date))
ORDER BY total_profit DESC
LIMIT 100
