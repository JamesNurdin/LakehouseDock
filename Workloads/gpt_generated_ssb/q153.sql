WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        d.d_year,
        s.s_region AS supplier_region,
        c.c_region AS customer_region
    FROM lineorder lo
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1997'
      AND p.p_category = 'MFGR#12'
      AND c.c_region = 'AMERICA'
)
SELECT
    d_year,
    supplier_region,
    customer_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM order_details
GROUP BY d_year, supplier_region, customer_region
ORDER BY total_revenue DESC
LIMIT 10
