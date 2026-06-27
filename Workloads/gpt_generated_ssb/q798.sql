WITH order_dates AS (
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
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
)
SELECT
    c.c_region,
    s.s_region,
    p.p_category,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    SUM(od.lo_quantity) AS total_quantity
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE od.order_year = '1995'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.order_year
ORDER BY total_profit DESC
LIMIT 20
