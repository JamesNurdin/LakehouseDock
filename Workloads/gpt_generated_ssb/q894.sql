WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        dd.d_year,
        cu.c_region,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(dd.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer cu
        ON lo.lo_custkey = cu.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#1'
      AND s.s_region = 'AMERICA'
      AND dd.d_year = '1997'
)
SELECT
    filtered_orders.d_year AS year,
    filtered_orders.c_region AS customer_region,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    AVG(filtered_orders.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM filtered_orders
GROUP BY filtered_orders.d_year, filtered_orders.c_region
ORDER BY total_revenue DESC
