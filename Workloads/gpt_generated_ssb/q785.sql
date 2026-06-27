WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_revenue,
        lo.lo_ordertotalprice,
        lo.lo_shipmode,
        d.d_year AS order_year,
        d.d_date AS order_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region,
    c.c_nation,
    s.s_region AS supplier_region,
    p.p_category,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_extendedprice - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS order_count,
    AVG(od.lo_quantity) AS avg_quantity
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    c.c_nation,
    s.s_region,
    p.p_category,
    od.order_year
ORDER BY total_revenue DESC
LIMIT 10
