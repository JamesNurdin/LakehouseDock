/* Revenue and profit by year, customer region, and part category for orders placed in 1997 */
WITH order_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1997'
)
SELECT
    od.d_year AS year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN order_date od
    ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
