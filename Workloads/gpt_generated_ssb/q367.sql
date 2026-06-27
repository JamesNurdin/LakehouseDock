WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year  AS order_year,
        d_order.d_month AS order_month,
        d_order.d_date  AS order_date,
        d_commit.d_year  AS commit_year,
        d_commit.d_month AS commit_month,
        d_commit.d_date  AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    od.order_year,
    od.order_month,
    p.p_category,
    s.s_region,
    c.c_mktsegment,
    COUNT(DISTINCT od.lo_orderkey)               AS num_orders,
    SUM(od.lo_quantity)                         AS total_quantity,
    SUM(od.lo_revenue)                          AS total_revenue,
    SUM(od.lo_supplycost)                       AS total_supplycost,
    SUM(od.lo_revenue - od.lo_supplycost)       AS total_profit,
    AVG(od.lo_discount)                         AS avg_discount
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE CAST(od.order_date AS date) >= DATE '1997-01-01'
  AND CAST(od.order_date AS date) <  DATE '1998-01-01'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category   = 'MFGR#1'
  AND od.lo_discount > 0
GROUP BY
    od.order_year,
    od.order_month,
    p.p_category,
    s.s_region,
    c.c_mktsegment
ORDER BY total_profit DESC
LIMIT 100
