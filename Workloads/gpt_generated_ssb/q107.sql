WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year,
        od.d_date,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        c.c_region AS customer_region
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#1'
      AND s.s_region = 'AMERICA'
)
SELECT
    supplier_region,
    customer_region,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM order_data
GROUP BY supplier_region, customer_region, p_brand1
ORDER BY total_profit DESC
LIMIT 10
