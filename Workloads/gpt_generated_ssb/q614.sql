WITH filtered_orders AS (
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
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
)
SELECT
    d.d_year AS year,
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS category,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
    AVG(f.lo_discount) AS avg_discount,
    COUNT(DISTINCT f.lo_orderkey) AS order_count
FROM filtered_orders f
JOIN dim_date d
    ON CAST(d.d_datekey AS integer) = f.lo_orderdate
JOIN customer c
    ON f.lo_custkey = c.c_custkey
JOIN part p
    ON f.lo_partkey = p.p_partkey
JOIN supplier s
    ON f.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
