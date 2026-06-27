WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region,
        s.s_region,
        p.p_category,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE p.p_category = 'MFGR#12'
      AND CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
)
SELECT
    d_year,
    c_region,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_details
GROUP BY d_year, c_region, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 10
