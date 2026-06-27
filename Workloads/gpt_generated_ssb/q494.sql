WITH order_info AS (
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
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_com.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
)
SELECT
    c.c_region,
    p.p_category,
    SUM(oi.lo_revenue) AS total_revenue,
    SUM(oi.lo_supplycost) AS total_supply_cost,
    SUM(oi.lo_quantity) AS total_quantity,
    COUNT(DISTINCT oi.lo_orderkey) AS distinct_orders
FROM order_info oi
JOIN customer c
    ON oi.lo_custkey = c.c_custkey
JOIN part p
    ON oi.lo_partkey = p.p_partkey
WHERE oi.order_year = '1995'
GROUP BY c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
