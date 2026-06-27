WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        c.c_mktsegment,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN customer c   ON lo.lo_custkey = c.c_custkey
    JOIN part     p   ON lo.lo_partkey = p.p_partkey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#1'
      AND lo.lo_shipmode = 'AIR'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    od.d_year                AS order_year,
    fo.s_region              AS supplier_region,
    SUM(fo.lo_revenue)       AS total_revenue,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit,
    AVG(fo.lo_discount)      AS avg_discount,
    COUNT(*)                 AS order_count
FROM filtered_orders fo
JOIN dim_date od ON CAST(fo.lo_orderdate AS VARCHAR) = od.d_datekey
GROUP BY od.d_year, fo.s_region
ORDER BY od.d_year, fo.s_region
