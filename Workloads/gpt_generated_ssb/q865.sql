WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderdate
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM orders_1995 lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
GROUP BY c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
