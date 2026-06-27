WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_commitdate AS varchar) = d.d_datekey
    WHERE d.d_year IN ('1995', '1996')
)
SELECT
    o.d_year,
    s.s_region,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders,
    SUM(o.lo_revenue) / SUM(SUM(o.lo_revenue)) OVER (PARTITION BY o.d_year, s.s_region) AS revenue_share
FROM orders o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND o.lo_shipmode = 'AIR'
GROUP BY o.d_year, s.s_region, p.p_category
ORDER BY o.d_year, s.s_region, p.p_category
