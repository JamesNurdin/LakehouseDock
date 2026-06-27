WITH order_data AS (
    SELECT
        d.d_year,
        c.c_region,
        p.p_category,
        s.s_nation,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND lo.lo_discount > 5
)
SELECT
    d_year,
    c_region,
    p_category,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(*) AS order_count
FROM order_data
GROUP BY d_year, c_region, p_category, s_nation
ORDER BY total_revenue DESC
LIMIT 100
