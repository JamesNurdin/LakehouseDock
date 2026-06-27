WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c.c_region,
    p.p_category,
    od.d_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_quantity) AS total_quantity,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_count
FROM order_dates od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
GROUP BY c.c_region, p.p_category, od.d_year
ORDER BY total_revenue DESC
LIMIT 100
