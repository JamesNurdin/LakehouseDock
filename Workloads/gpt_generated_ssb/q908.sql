WITH order_facts AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity
    FROM lineorder lo
)
SELECT
    od.d_year AS year,
    c.c_region AS region,
    p.p_category AS category,
    SUM(of.lo_revenue) AS total_revenue,
    SUM(of.lo_revenue - of.lo_supplycost) AS total_profit,
    AVG(of.lo_discount) AS avg_discount,
    COUNT(DISTINCT of.lo_orderkey) AS order_count
FROM order_facts of
JOIN dim_date od ON of.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN dim_date cd ON of.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c ON of.lo_custkey = c.c_custkey
JOIN part p ON of.lo_partkey = p.p_partkey
JOIN supplier s ON of.lo_suppkey = s.s_suppkey
WHERE od.d_year BETWEEN '1994' AND '1996'
  AND c.c_region = 'Europe'
  AND p.p_category = 'MFGR#12'
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
