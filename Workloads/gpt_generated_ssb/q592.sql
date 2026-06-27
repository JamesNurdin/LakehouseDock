WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_shipmode,
        dd.d_year AS order_year,
        dd.d_month AS order_month
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(lo.lo_orderdate AS varchar) = dd.d_datekey
    WHERE dd.d_year = '1997'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS product_category,
    fo.order_year,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    AVG(fo.lo_discount) AS avg_discount,
    COUNT(DISTINCT fo.lo_custkey) AS distinct_customers,
    COUNT(*) AS order_lines
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
JOIN part p
    ON fo.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    fo.order_year
ORDER BY total_revenue DESC
LIMIT 20
