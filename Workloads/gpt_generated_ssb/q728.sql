WITH lo_cust_date AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_custkey,
        lo.lo_orderdate,
        c.c_region,
        c.c_nation,
        d.d_year,
        d.d_month,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
)
SELECT
    c_region,
    c_nation,
    d_year,
    d_month,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM lo_cust_date
WHERE c_region = 'ASIA'
  AND CAST(d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    c_region,
    c_nation,
    d_year,
    d_month
ORDER BY total_revenue DESC
LIMIT 20
