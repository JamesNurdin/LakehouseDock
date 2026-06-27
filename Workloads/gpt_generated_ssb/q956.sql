WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od  ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd  ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
)
SELECT
    lo_joined.order_year,
    c.c_region,
    s.s_region AS supplier_region,
    p.p_category,
    SUM(lo_joined.lo_revenue) AS total_revenue,
    SUM(lo_joined.lo_revenue - lo_joined.lo_supplycost) AS total_profit,
    AVG(lo_joined.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_joined.lo_orderkey) AS num_orders
FROM lo_joined
JOIN customer c   ON lo_joined.lo_custkey = c.c_custkey
JOIN part p       ON lo_joined.lo_partkey = p.p_partkey
JOIN supplier s   ON lo_joined.lo_suppkey = s.s_suppkey
WHERE lo_joined.order_year = '1995'
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'ASIA'
GROUP BY lo_joined.order_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
