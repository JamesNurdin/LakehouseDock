WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        od.d_year,
        od.d_month,
        od.d_date,
        c.c_region AS customer_region,
        p.p_category,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND p.p_category = 'MFGR#12'
)
SELECT
    order_data.d_year,
    order_data.p_category,
    order_data.supplier_region,
    sum(order_data.lo_revenue) AS total_revenue,
    sum(order_data.lo_revenue - order_data.lo_supplycost) AS total_profit,
    avg(order_data.lo_discount) AS avg_discount,
    count(DISTINCT order_data.lo_orderkey) AS order_cnt
FROM order_data
GROUP BY order_data.d_year, order_data.p_category, order_data.supplier_region
ORDER BY total_revenue DESC
