WITH order_profit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_revenue - lo.lo_supplycost AS profit
    FROM lineorder lo
)
SELECT
    d.d_year,
    c.c_region,
    sum(op.lo_revenue) AS total_revenue,
    sum(op.profit) AS total_profit,
    avg(op.lo_discount) AS avg_discount,
    count(distinct op.lo_orderkey) AS order_count
FROM order_profit op
JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = op.lo_orderdate
JOIN customer c ON op.lo_custkey = c.c_custkey
JOIN part p ON op.lo_partkey = p.p_partkey
JOIN supplier s ON op.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1995'
  AND c.c_region = 'AMERICA'
  AND p.p_category = 'MFGR#1'
  AND s.s_nation = 'UNITED STATES'
GROUP BY d.d_year, c.c_region
ORDER BY sum(op.lo_revenue) DESC
