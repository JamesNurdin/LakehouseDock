WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year AS order_year,
        cd.d_year AS commit_year,
        s.s_region,
        s.s_nation,
        p.p_category,
        c.c_mktsegment
    FROM lineorder lo
    JOIN dim_date od ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year IN ('1995', '1996')
      AND p.p_category = 'MFGR#12'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    order_year,
    s_region,
    COUNT(DISTINCT lo_orderkey) AS order_cnt,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM order_data
GROUP BY order_year, s_region
ORDER BY total_revenue DESC
