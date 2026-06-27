WITH order_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year = '1995'
),
order_with_customer AS (
    SELECT
        o1995.lo_orderkey,
        o1995.lo_custkey,
        o1995.lo_partkey,
        o1995.lo_suppkey,
        o1995.lo_extendedprice,
        o1995.lo_discount,
        o1995.lo_revenue,
        o1995.lo_quantity,
        c.c_region AS cust_region,
        c.c_mktsegment AS cust_mktsegment
    FROM order_1995 o1995
    JOIN customer c
        ON o1995.lo_custkey = c.c_custkey
)
SELECT
    s.s_region AS supplier_region,
    owc.cust_region,
    p.p_category,
    SUM(owc.lo_extendedprice) AS total_extendedprice,
    SUM(owc.lo_revenue) AS total_revenue,
    AVG(owc.lo_discount) AS avg_discount,
    COUNT(DISTINCT owc.lo_custkey) AS distinct_customers,
    COUNT(*) AS order_count
FROM order_with_customer owc
JOIN part p
    ON owc.lo_partkey = p.p_partkey
JOIN supplier s
    ON owc.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, owc.cust_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
