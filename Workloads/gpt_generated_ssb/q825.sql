SELECT
    d_order.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS product_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d_order
    ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
JOIN dim_date d_commit
    ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
  AND d_commit.d_year = '1995'
  AND c.c_region IN ('AMERICA', 'EUROPE')
  AND p.p_category = 'MFGR#12'
GROUP BY d_order.d_year, c.c_region, p.p_category
HAVING SUM(lo.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100
