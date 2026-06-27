/* Revenue, profit and order count by supplier region, part category and month for the year 1995 */
WITH orders_95 AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_orderkey,
        d.d_year,
        d.d_monthnuminyear,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
)
SELECT
    o.d_year,
    o.d_monthnuminyear,
    o.s_region,
    o.p_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    COUNT(DISTINCT o.lo_orderkey) AS order_count
FROM orders_95 o
GROUP BY o.d_year, o.d_monthnuminyear, o.s_region, o.p_category
ORDER BY total_revenue DESC
LIMIT 20
