WITH order_base AS (
    SELECT
        lo.lo_orderkey,
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
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_shipmode,
        lo.lo_linenumber
    FROM lineorder lo
)
SELECT
    od.d_year AS order_year,
    s.s_region,
    p.p_category,
    SUM(ob.lo_revenue) AS total_revenue,
    SUM(ob.lo_revenue - ob.lo_supplycost - ob.lo_tax) AS total_profit,
    AVG(ob.lo_discount) AS avg_discount,
    AVG(date_diff('day', DATE(od.d_date), DATE(cm.d_date))) AS avg_lead_time_days,
    COUNT(DISTINCT ob.lo_orderkey) AS order_count
FROM order_base ob
JOIN dim_date od
    ON CAST(ob.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cm
    ON CAST(ob.lo_commitdate AS varchar) = cm.d_datekey
JOIN supplier s
    ON ob.lo_suppkey = s.s_suppkey
JOIN part p
    ON ob.lo_partkey = p.p_partkey
JOIN customer c
    ON ob.lo_custkey = c.c_custkey
WHERE DATE(od.d_date) >= DATE '1995-01-01'
  AND DATE(od.d_date) <= DATE '1995-12-31'
GROUP BY od.d_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
