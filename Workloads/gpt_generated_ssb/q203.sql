WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_date,
        od.d_year,
        c.c_region AS cust_region,
        c.c_nation AS cust_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region,
        s.s_nation AS supp_nation
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
)
SELECT
    cust_region,
    supp_region,
    p_category,
    COUNT(DISTINCT lo_orderkey) AS order_cnt,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM order_data
GROUP BY cust_region, supp_region, p_category
ORDER BY total_revenue DESC
LIMIT 100
