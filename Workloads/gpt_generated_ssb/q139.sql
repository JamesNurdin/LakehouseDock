WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year AS order_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
    s.s_region,
    p.p_category,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1995'
  AND s.s_region = 'ASIA'
  AND p.p_category = 'MFGR#1'
GROUP BY s.s_region, p.p_category, od.order_year
ORDER BY total_revenue DESC
LIMIT 5
