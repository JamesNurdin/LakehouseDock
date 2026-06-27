WITH order_data AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_extendedprice,
        lo_revenue,
        lo_discount,
        lo_quantity,
        lo_tax
    FROM lineorder
)
SELECT
    d_order.d_year AS order_year,
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_discount) AS total_discount,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_tax) AS avg_tax
FROM order_data lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1997'
GROUP BY d_order.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
