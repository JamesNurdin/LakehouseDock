WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        d.d_year,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE CAST(d.d_date AS DATE) >= DATE '1997-01-01'
      AND CAST(d.d_date AS DATE) < DATE '1998-01-01'
)
SELECT
    d_year,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost * lo_quantity) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_data
GROUP BY d_year, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 10
