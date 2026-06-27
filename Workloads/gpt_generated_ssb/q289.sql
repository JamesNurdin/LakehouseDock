WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    WHERE lo.lo_revenue > 0
)
SELECT
    d.d_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount
FROM order_details od
JOIN dim_date d
    ON od.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
