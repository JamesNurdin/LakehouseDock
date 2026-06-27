WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_partkey,
        lo.lo_suppkey,
        od.d_year
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    WHERE date(od.d_date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    fo.d_year,
    s.s_region,
    p.p_category,
    SUM(fo.lo_revenue) AS total_revenue,
    COUNT(DISTINCT fo.lo_orderkey) AS order_count
FROM filtered_orders fo
JOIN part p
    ON fo.lo_partkey = p.p_partkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY fo.d_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
