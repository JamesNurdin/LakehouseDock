WITH orders_filtered AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_discount,
        p.p_category,
        s.s_region,
        od.d_year AS order_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND lo.lo_commitdate > lo.lo_orderdate
      AND p.p_category = 'MFGR#1'
)
SELECT
    s_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_cnt
FROM orders_filtered
GROUP BY s_region, p_category
ORDER BY total_revenue DESC
