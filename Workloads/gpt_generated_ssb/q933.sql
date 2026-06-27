WITH filtered_orders AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    d.d_year,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM filtered_orders lo
JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
GROUP BY d.d_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
