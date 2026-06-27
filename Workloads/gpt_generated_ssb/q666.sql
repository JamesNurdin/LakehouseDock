WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_date AS order_date,
        od.d_year AS order_year,
        cd.d_date AS commit_date,
        cd.d_year AS commit_year,
        cust.c_region,
        cust.c_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN customer cust ON lo.lo_custkey = cust.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    order_year,
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_details
WHERE CAST(order_date AS date) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY order_year, c_region, p_category
ORDER BY total_revenue DESC
LIMIT 10
