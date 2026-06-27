WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    WHERE d_order.d_year = '1995'
)
SELECT
    o.order_year,
    p.p_category,
    c.c_region,
    s.s_nation,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_supplycost) AS total_supply_cost,
    SUM(o.lo_revenue) - SUM(o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount
FROM orders_1995 o
JOIN dim_date d_commit
    ON o.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
WHERE CAST(d_commit.d_datekey AS INTEGER) >= o.lo_orderdate
GROUP BY
    o.order_year,
    p.p_category,
    c.c_region,
    s.s_nation
ORDER BY total_revenue DESC
LIMIT 100
