WITH order_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
),
commit_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
)
SELECT 
    od.d_year AS order_year,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN order_date od
    ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN commit_date cd
    ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
WHERE od.d_year BETWEEN '1993' AND '1997'
  AND CAST(cd.d_year AS integer) >= CAST(od.d_year AS integer)
GROUP BY od.d_year, s.s_region, p.p_category
ORDER BY od.d_year, s.s_region, p.p_category
