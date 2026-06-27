WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        dd.d_year
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(lo.lo_orderdate AS VARCHAR) = dd.d_datekey
    WHERE dd.d_year = '1995'
)
SELECT
    o.d_year AS year,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(o.lo_extendedprice * (1 - o.lo_discount / 100.0)) AS total_revenue,
    SUM(o.lo_supplycost) AS total_supply_cost,
    SUM(o.lo_extendedprice * (1 - o.lo_discount / 100.0)) - SUM(o.lo_supplycost) AS profit,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders,
    AVG(o.lo_discount) AS avg_discount
FROM orders_1995 o
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
GROUP BY
    o.d_year,
    s.s_region,
    p.p_category
ORDER BY
    total_revenue DESC
LIMIT 20
