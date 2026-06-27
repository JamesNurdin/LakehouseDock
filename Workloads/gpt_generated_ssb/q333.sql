WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        CAST(od.d_datekey AS integer)        AS order_date_key,
        od.d_date                             AS order_date,
        od.d_year                             AS order_year,
        CAST(cd.d_datekey AS integer)        AS commit_date_key,
        cd.d_date                             AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    c.c_region        AS customer_region,
    s.s_region        AS supplier_region,
    p.p_category      AS product_category,
    od.order_year,
    SUM(od.lo_revenue)                         AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost)      AS total_profit,
    AVG(od.lo_discount)                        AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey)            AS order_count
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE od.order_year = '1997'
GROUP BY c.c_region, s.s_region, p.p_category, od.order_year
ORDER BY total_revenue DESC
LIMIT 100
