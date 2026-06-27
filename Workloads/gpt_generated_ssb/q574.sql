WITH orders_1995 AS (
    SELECT
        lo.lo_revenue,
        lo.lo_discount,
        od.d_year AS order_year,
        cd.d_year AS commit_year,
        c.c_region,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND cd.d_year = '1995'
)
SELECT
    order_year,
    c_region,
    p_category,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount
FROM orders_1995
GROUP BY order_year, c_region, p_category, s_region
ORDER BY total_revenue DESC
LIMIT 100
