WITH order_with_date AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderdate,
        dd.d_year,
        dd.d_month
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(dd.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE dd.d_year = '1995'
)
SELECT
    c.c_region,
    o.d_month,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_quantity) AS total_quantity,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS order_count
FROM order_with_date o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    o.d_month,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 10
