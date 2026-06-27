WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_commitdate,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_linenumber,
        d.d_date,
        d.d_year,
        d.d_month,
        d.d_dayofweek
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE d.d_date BETWEEN '1995-01-01' AND '1995-12-31'
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    od.d_year AS order_year,
    p.p_category AS product_category,
    SUM(od.lo_revenue) AS total_revenue,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_cnt
FROM order_dates od
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
JOIN part p ON od.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    s.s_region,
    od.d_year,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 10
