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
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_year AS order_year,
        od.d_month AS order_month,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_month AS commit_month,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1995'
)
SELECT
    c.c_region,
    s.s_region AS supplier_region,
    p.p_category,
    od.order_year,
    od.commit_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(*) AS order_count,
    SUM(CASE WHEN od.commit_year = od.order_year THEN 1 ELSE 0 END) AS same_year_commit_orders
FROM order_dates od
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN part p ON od.lo_partkey = p.p_partkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.order_year,
    od.commit_year
ORDER BY total_revenue DESC
LIMIT 20
