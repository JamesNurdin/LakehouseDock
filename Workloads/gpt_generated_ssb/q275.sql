WITH lo_with_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
)
SELECT
    lod.order_year,
    s.s_region,
    SUM(lod.lo_revenue) AS total_revenue,
    SUM(lod.lo_supplycost) AS total_supplycost,
    SUM(lod.lo_revenue) - SUM(lod.lo_supplycost) AS profit,
    AVG(lod.lo_discount) AS avg_discount,
    COUNT(DISTINCT lod.lo_orderkey) AS order_count
FROM lo_with_dates lod
JOIN supplier s
    ON lod.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lod.lo_custkey = c.c_custkey
JOIN part p
    ON lod.lo_partkey = p.p_partkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category = 'MFGR#12'
GROUP BY lod.order_year, s.s_region
ORDER BY profit DESC
LIMIT 10
