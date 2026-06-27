WITH orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year = '1997'
)
SELECT
    o.d_year AS order_year,
    s.s_region AS supplier_region,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_custkey) AS distinct_customers
FROM orders o
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN customer c
    ON o.lo_custkey = c.c_custkey
WHERE p.p_category = 'MFGR#12'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY o.d_year, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
