WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    s.s_region,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    SUM(o.lo_quantity) AS total_quantity,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders
FROM orders_1995 o
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
GROUP BY s.s_region, p.p_category
HAVING SUM(o.lo_revenue) > 1000000
ORDER BY total_profit DESC
LIMIT 10
