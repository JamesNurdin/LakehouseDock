WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
)
SELECT
    c.c_region,
    o.order_year,
    p.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(o.order_date AS date), CAST(o.commit_date AS date))) AS avg_lead_days,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders,
    COUNT(*) AS lineitem_count
FROM order_dates o
JOIN customer c ON o.lo_custkey = c.c_custkey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    o.order_year,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 100
