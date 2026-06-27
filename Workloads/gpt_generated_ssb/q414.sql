WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_discount,
        CAST(lo.lo_orderdate AS varchar) AS order_date_key
    FROM lineorder lo
),
date_filtered AS (
    SELECT
        d_datekey,
        d_year,
        d_month
    FROM dim_date
    WHERE d_year BETWEEN '1995' AND '1997'
)
SELECT
    s.s_nation,
    p.p_category,
    df.d_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders
FROM order_data od
JOIN date_filtered df ON od.order_date_key = df.d_datekey
JOIN part p ON od.lo_partkey = p.p_partkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
GROUP BY s.s_nation, p.p_category, df.d_year
ORDER BY total_revenue DESC
LIMIT 50
