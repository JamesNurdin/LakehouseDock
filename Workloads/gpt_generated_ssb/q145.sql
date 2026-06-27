WITH lo AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_shipmode,
        lo_orderpriority,
        lo_shippriority
    FROM lineorder
)
SELECT
    d_order.d_year AS order_year,
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year BETWEEN '1995' AND '1996'
  AND c.c_region = 'ASIA'
GROUP BY d_order.d_year, c.c_region, p.p_category, s.s_nation
ORDER BY total_revenue DESC
LIMIT 10
