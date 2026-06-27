SELECT
    s.s_region,
    p.p_category,
    COUNT(*) AS order_count,
    SUM(lo.lo_quantity) AS total_quantity,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(date_diff('day', date(d_order.d_date), date(d_commit.d_date))) AS avg_shipping_delay,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d_order
    ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
JOIN dim_date d_commit
    ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
WHERE d_order.d_year = '1995'
  AND lo.lo_shipmode = 'AIR'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
