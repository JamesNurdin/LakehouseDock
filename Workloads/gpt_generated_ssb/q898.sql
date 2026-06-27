WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_orderdate,
        d.d_year AS order_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    WHERE d.d_year = '1995'
)
SELECT
    o.order_year,
    c.c_region,
    p.p_category,
    s.s_region,
    SUM(o.lo_revenue) AS total_revenue,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS order_count
FROM orders o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
GROUP BY
    o.order_year,
    c.c_region,
    p.p_category,
    s.s_region
ORDER BY total_revenue DESC
