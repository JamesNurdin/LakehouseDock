WITH order_details AS (
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
        lo.lo_quantity,
        c.c_region,
        c.c_nation,
        p.p_category,
        s.s_region AS supplier_region,
        od.d_year,
        od.d_month,
        od.d_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c_region,
    c_nation,
    p_category,
    supplier_region,
    d_year,
    d_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    (SUM(lo_revenue - lo_supplycost) / NULLIF(SUM(lo_revenue), 0)) AS profit_margin,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM order_details
GROUP BY c_region, c_nation, p_category, supplier_region, d_year, d_month
ORDER BY total_revenue DESC
LIMIT 10
