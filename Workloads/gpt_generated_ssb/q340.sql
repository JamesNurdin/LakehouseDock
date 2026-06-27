SELECT
    od.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    s.s_nation AS supplier_nation,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date od
    ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY od.d_year, c.c_region, p.p_category, s.s_nation
ORDER BY total_profit DESC
LIMIT 10
