WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    s.s_region,
    p.p_category,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
    AVG(f.lo_discount) AS avg_discount,
    COUNT(DISTINCT f.lo_custkey) AS distinct_customers
FROM filtered_orders f
JOIN supplier s
    ON f.lo_suppkey = s.s_suppkey
JOIN part p
    ON f.lo_partkey = p.p_partkey
JOIN customer c
    ON f.lo_custkey = c.c_custkey
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
