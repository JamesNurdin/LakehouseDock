WITH lo_joined AS (
    SELECT 
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_year,
        d.d_date,
        c.c_region,
        p.p_category,
        s.s_region
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
      AND lo.lo_shipmode = 'AIR'
)
SELECT 
    d_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lo_joined
GROUP BY d_year, c_region, p_category
ORDER BY d_year, total_revenue DESC
