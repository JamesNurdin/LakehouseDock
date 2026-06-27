SELECT
    d.d_year AS order_year,
    s.s_region AS supplier_region,
    c.c_mktsegment AS customer_market_segment,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
GROUP BY d.d_year, s.s_region, c.c_mktsegment, p.p_category
ORDER BY profit DESC
LIMIT 10
