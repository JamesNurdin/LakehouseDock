SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category,
    d.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date d
    ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY c.c_region, s.s_region, p.p_category, d.d_year
ORDER BY total_revenue DESC
LIMIT 100
