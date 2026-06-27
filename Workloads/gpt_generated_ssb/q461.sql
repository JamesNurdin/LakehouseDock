WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_quantity,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    WHERE d_order.d_year = '1995'
)
SELECT
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue - od.lo_supplycost - od.lo_tax) AS total_profit,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(date_diff('day', CAST(od.order_date AS DATE), CAST(od.commit_date AS DATE))) AS avg_lead_days
FROM orders od
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 100
