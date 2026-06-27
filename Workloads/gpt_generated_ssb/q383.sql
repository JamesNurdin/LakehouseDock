WITH lineorder_extended AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
)
SELECT
    d.d_year,
    c.c_region,
    SUM(loe.lo_revenue) AS total_revenue,
    SUM(loe.profit) AS total_profit,
    AVG(loe.lo_discount) AS avg_discount,
    COUNT(DISTINCT loe.lo_orderkey) AS order_count
FROM lineorder_extended loe
JOIN dim_date d
    ON CAST(d.d_datekey AS INTEGER) = loe.lo_orderdate
JOIN customer c
    ON loe.lo_custkey = c.c_custkey
JOIN part p
    ON loe.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
GROUP BY d.d_year, c.c_region
ORDER BY d.d_year, c.c_region
