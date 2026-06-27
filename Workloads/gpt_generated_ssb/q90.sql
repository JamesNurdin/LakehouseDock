-- Total revenue, profit, average discount and distinct order count by year, supplier region and part category for 1995 orders with discount between 5 and 10
WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        d.d_date,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND lo.lo_discount BETWEEN 5 AND 10
)
SELECT
    d_year,
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_details
GROUP BY d_year, s_region, p_category
ORDER BY total_revenue DESC
LIMIT 20
