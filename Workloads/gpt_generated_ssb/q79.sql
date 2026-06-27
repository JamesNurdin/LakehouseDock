WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_commitdate,
        d.d_year AS order_year,
        d.d_month AS order_month,
        d.d_date AS order_date
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1995'
)
SELECT
    c.c_region,
    p.p_category,
    o.order_year,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders,
    COUNT(*) AS line_items
FROM orders_1995 o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
GROUP BY c.c_region, p.p_category, o.order_year
ORDER BY total_revenue DESC
LIMIT 20
