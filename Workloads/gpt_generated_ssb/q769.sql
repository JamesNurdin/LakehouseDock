WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_shipmode,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1997'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    c.c_region,
    s.s_region,
    f.d_year,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_revenue - f.lo_supplycost) AS total_profit,
    AVG(f.lo_discount) AS avg_discount,
    COUNT(DISTINCT f.lo_orderkey) AS order_count
FROM filtered_orders f
JOIN customer c
    ON f.lo_custkey = c.c_custkey
JOIN supplier s
    ON f.lo_suppkey = s.s_suppkey
JOIN part p
    ON f.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#1'
GROUP BY c.c_region, s.s_region, f.d_year
ORDER BY total_revenue DESC
LIMIT 10
