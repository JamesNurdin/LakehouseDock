WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
)
SELECT
    fo.d_year,
    p.p_category,
    p.p_brand1,
    SUM(fo.lo_revenue) AS total_revenue,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_custkey) AS distinct_customers,
    COUNT(*) AS order_count
FROM filtered_orders fo
JOIN part p
    ON fo.lo_partkey = p.p_partkey
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
  AND s.s_region = 'ASIA'
GROUP BY fo.d_year, p.p_category, p.p_brand1
ORDER BY total_revenue DESC
LIMIT 10
