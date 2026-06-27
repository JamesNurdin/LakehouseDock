WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_com.d_year AS commit_year,
        d_com.d_month AS commit_month
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
)
SELECT
    s.s_region,
    p.p_category,
    order_info.order_year,
    SUM(order_info.lo_revenue) AS total_revenue,
    AVG(order_info.lo_discount) AS avg_discount,
    COUNT(DISTINCT order_info.lo_orderkey) AS distinct_orders,
    SUM(order_info.lo_extendedprice * order_info.lo_quantity) AS total_extendedprice_quantity
FROM order_info
JOIN customer c
    ON order_info.lo_custkey = c.c_custkey
JOIN part p
    ON order_info.lo_partkey = p.p_partkey
JOIN supplier s
    ON order_info.lo_suppkey = s.s_suppkey
WHERE order_info.order_year = '1995'
  AND p.p_category = 'MFGR#12'
GROUP BY s.s_region, p.p_category, order_info.order_year
ORDER BY total_revenue DESC
