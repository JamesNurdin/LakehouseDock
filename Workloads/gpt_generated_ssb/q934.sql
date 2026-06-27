WITH order_data AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_extendedprice,
        lo_discount,
        lo_supplycost,
        lo_tax,
        lo_extendedprice * (100 - lo_discount) / 100.0 AS revenue,
        (lo_extendedprice * (100 - lo_discount) / 100.0) - lo_supplycost AS profit
    FROM lineorder
)
SELECT
    s.s_region AS supplier_region,
    od_year.d_year AS order_year,
    p.p_category AS part_category,
    SUM(od.revenue) AS total_revenue,
    SUM(od.profit) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_data od
JOIN dim_date od_year   ON CAST(od_year.d_datekey AS integer) = od.lo_orderdate
JOIN dim_date od_commit ON CAST(od_commit.d_datekey AS integer) = od.lo_commitdate
JOIN part p             ON od.lo_partkey = p.p_partkey
JOIN supplier s         ON od.lo_suppkey = s.s_suppkey
JOIN customer c         ON od.lo_custkey = c.c_custkey
WHERE p.p_category = 'MFGR#12'
  AND od_year.d_year = '1995'
GROUP BY s.s_region, od_year.d_year, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
