WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    order_info.order_year,
    s.s_region,
    p.p_category,
    SUM(order_info.lo_revenue) AS total_revenue,
    SUM(order_info.lo_revenue - order_info.lo_supplycost) AS total_profit,
    COUNT(DISTINCT order_info.lo_orderkey) AS distinct_orders
FROM order_info
JOIN customer c ON order_info.lo_custkey = c.c_custkey
JOIN supplier s ON order_info.lo_suppkey = s.s_suppkey
JOIN part p ON order_info.lo_partkey = p.p_partkey
WHERE order_info.order_date BETWEEN '1995-01-01' AND '1995-12-31'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category = 'MFGR#12'
GROUP BY order_info.order_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
