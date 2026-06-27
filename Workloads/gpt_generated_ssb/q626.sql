WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.order_date AS DATE), CAST(od.commit_date AS DATE))) AS avg_days_to_commit,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE CAST(od.order_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1998-12-31'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND s.s_region = 'ASIA'
GROUP BY od.order_year, c.c_region, p.p_category
HAVING SUM(od.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100
