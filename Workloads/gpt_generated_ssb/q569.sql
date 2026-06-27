WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_suppkey,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    f.d_year,
    s.s_region,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
    AVG(f.lo_discount) AS avg_discount,
    COUNT(DISTINCT f.lo_orderkey) AS order_count
FROM filtered_orders f
JOIN supplier s
    ON f.lo_suppkey = s.s_suppkey
GROUP BY f.d_year, s.s_region
ORDER BY total_revenue DESC
