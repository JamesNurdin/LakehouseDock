-- Revenue, profit and discount analysis per customer region, supplier region,
-- part category and order year for the year 1995
WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region,
        s.s_region AS supplier_region,
        p.p_category,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c_region,
    supplier_region,
    p_category,
    d_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_details
GROUP BY c_region, supplier_region, p_category, d_year
ORDER BY total_revenue DESC
LIMIT 100
