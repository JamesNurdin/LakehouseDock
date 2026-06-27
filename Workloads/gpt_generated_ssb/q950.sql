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
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_order.d_date AS order_date,
        d_order.d_year AS order_year,
        d_commit.d_date AS commit_date,
        d_commit.d_year AS commit_year,
        date_diff('day', CAST(d_commit.d_date AS DATE), CAST(d_order.d_date AS DATE)) AS lead_time_days
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
)
SELECT
    od.order_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    AVG(od.lead_time_days) AS avg_lead_time_days,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE CAST(od.order_date AS DATE) BETWEEN DATE '1993-01-01' AND DATE '1995-12-31'
  AND p.p_category = 'MFGR#14'
GROUP BY
    od.order_year,
    c.c_region,
    s.s_region,
    p.p_category
ORDER BY total_profit DESC
LIMIT 10
