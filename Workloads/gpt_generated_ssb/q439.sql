WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_order.d_date AS order_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
)
SELECT
    od.order_year,
    od.order_month,
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(od.lo_extendedprice * (1 - od.lo_discount / 100.0)) AS revenue,
    SUM(od.lo_quantity) AS total_quantity,
    COUNT(DISTINCT od.lo_custkey) AS distinct_customers
FROM order_data od
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN part p ON od.lo_partkey = p.p_partkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
WHERE od.order_date BETWEEN '1997-01-01' AND '1997-12-31'
  AND c.c_region = 'ASIA'
GROUP BY od.order_year, od.order_month, c.c_region, p.p_category, s.s_nation
ORDER BY od.order_year, od.order_month, revenue DESC
LIMIT 100
