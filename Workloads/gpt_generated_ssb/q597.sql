WITH lo_with_dates AS (
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
        od_order.d_year AS order_year,
        od_order.d_date AS order_date,
        od_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od_order
        ON CAST(od_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date od_commit
        ON CAST(od_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE od_order.d_year >= '1992' AND od_order.d_year <= '1997'
)
SELECT
    lo.order_year,
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lo_with_dates lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_size > 20
  AND s.s_region = 'ASIA'
GROUP BY lo.order_year, c.c_region, p.p_category
ORDER BY lo.order_year, c.c_region, p.p_category
