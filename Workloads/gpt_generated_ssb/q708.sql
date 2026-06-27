WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE d.d_year = '1995'
)
SELECT
    c.c_region        AS customer_region,
    s.s_region        AS supplier_region,
    p.p_category,
    od.d_year,
    SUM(od.lo_revenue)                         AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost)      AS total_profit,
    COUNT(DISTINCT od.lo_orderkey)             AS order_count
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.d_year
ORDER BY total_revenue DESC
LIMIT 100
