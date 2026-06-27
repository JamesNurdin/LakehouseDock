WITH orders_by_region AS (
    SELECT
        l.lo_orderkey,
        c.c_region,
        d_o.d_year,
        d_o.d_month,
        l.lo_revenue,
        l.lo_discount
    FROM lineorder l
    JOIN customer c
      ON l.lo_custkey = c.c_custkey
    JOIN dim_date d_o
      ON CAST(d_o.d_datekey AS integer) = l.lo_orderdate
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND d_o.d_year = '1995'
)
SELECT
    c_region,
    d_year,
    d_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_discount) AS total_discount,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM orders_by_region
GROUP BY c_region, d_year, d_month
ORDER BY total_revenue DESC
LIMIT 10
