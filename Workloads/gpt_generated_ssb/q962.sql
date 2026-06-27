WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE d.d_year = '1995'
)
SELECT
    o.d_year,
    c.c_region,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount
FROM orders_1995 o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
GROUP BY o.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
