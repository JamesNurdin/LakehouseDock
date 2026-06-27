WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        CAST(lo.lo_orderdate AS varchar) AS order_datekey,
        CAST(lo.lo_commitdate AS varchar) AS commit_datekey
    FROM lineorder lo
)
SELECT
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    d_order.d_year AS order_year,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    AVG(od.lo_discount) AS avg_discount,
    AVG(
        date_diff('day', CAST(d_order.d_date AS date), CAST(d_commit.d_date AS date))
    ) AS avg_lead_time_days
FROM order_dates od
JOIN dim_date d_order
    ON od.order_datekey = d_order.d_datekey
JOIN dim_date d_commit
    ON od.commit_datekey = d_commit.d_datekey
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
GROUP BY s.s_region, p.p_category, d_order.d_year
ORDER BY total_revenue DESC
LIMIT 10
