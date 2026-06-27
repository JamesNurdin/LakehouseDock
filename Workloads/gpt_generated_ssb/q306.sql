WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_tax,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_com.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS varchar) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS varchar) = d_com.d_datekey
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(od.lo_revenue) AS total_revenue,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1995'
  AND p.p_category = 'MFGR#1'
  AND s.s_region = 'ASIA'
GROUP BY od.order_year, c.c_region, p.p_category, s.s_nation
ORDER BY total_revenue DESC
LIMIT 50
