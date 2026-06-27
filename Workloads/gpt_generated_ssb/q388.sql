WITH revenue_by_order AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_orderdate,
        lo.lo_partkey,
        lo.lo_suppkey
    FROM lineorder lo
)
SELECT
    d.d_year,
    p.p_category,
    s.s_region,
    SUM(r.lo_revenue) AS total_revenue,
    COUNT(DISTINCT r.lo_orderkey) AS order_count
FROM revenue_by_order r
JOIN dim_date d
    ON r.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN part p
    ON r.lo_partkey = p.p_partkey
JOIN supplier s
    ON r.lo_suppkey = s.s_suppkey
WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY d.d_year, p.p_category, s.s_region
ORDER BY total_revenue DESC
