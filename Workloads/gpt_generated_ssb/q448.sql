WITH order_summary AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category,
        d.d_year,
        lo.lo_revenue
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
)
SELECT
    customer_region,
    supplier_region,
    p_category,
    d_year,
    SUM(lo_revenue) AS total_revenue
FROM order_summary
GROUP BY customer_region, supplier_region, p_category, d_year
ORDER BY total_revenue DESC
LIMIT 10
