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
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#1'
      AND p.p_brand1 = 'Brand#31'
)
SELECT
    c.c_region,
    d.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM filtered_orders lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1995'
GROUP BY c.c_region, d.d_year
ORDER BY total_revenue DESC
LIMIT 20
