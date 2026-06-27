WITH lo_joined AS (
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
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    order_year,
    c_region,
    p_category,
    supplier_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extendedprice,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_line_count
FROM lo_joined
GROUP BY order_year, c_region, p_category, supplier_region
ORDER BY total_revenue DESC
