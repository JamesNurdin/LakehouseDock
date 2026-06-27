WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_discount,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
      ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
      ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
)
SELECT
    c.c_region,
    oi.order_year,
    p.p_category,
    SUM(oi.lo_revenue) AS total_revenue,
    SUM(oi.lo_quantity) AS total_quantity,
    AVG(oi.lo_discount) AS avg_discount,
    COUNT(DISTINCT oi.lo_orderkey) AS distinct_orders
FROM order_info oi
JOIN customer c
  ON oi.lo_custkey = c.c_custkey
JOIN part p
  ON oi.lo_partkey = p.p_partkey
WHERE oi.order_year = '1995'
  AND oi.commit_year = '1995'
GROUP BY c.c_region, oi.order_year, p.p_category
ORDER BY total_revenue DESC
LIMIT 50
