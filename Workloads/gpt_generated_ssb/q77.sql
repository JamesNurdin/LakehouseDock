WITH dim_order AS (
    SELECT
        CAST(d_datekey AS INTEGER) AS date_key,
        d_year,
        d_month,
        d_date
    FROM dim_date
),
dim_commit AS (
    SELECT
        CAST(d_datekey AS INTEGER) AS date_key,
        d_year AS commit_year,
        d_month AS commit_month,
        d_date AS commit_date
    FROM dim_date
)
SELECT
    c.c_region,
    d_order.d_year AS order_year,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS net_sales,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers
FROM lineorder lo
INNER JOIN dim_order d_order
    ON d_order.date_key = lo.lo_orderdate
INNER JOIN dim_commit d_commit
    ON d_commit.date_key = lo.lo_commitdate
INNER JOIN customer c
    ON lo.lo_custkey = c.c_custkey
INNER JOIN part p
    ON lo.lo_partkey = p.p_partkey
INNER JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
  AND c.c_region = 'ASIA'
GROUP BY c.c_region, d_order.d_year
ORDER BY net_sales DESC
LIMIT 10
