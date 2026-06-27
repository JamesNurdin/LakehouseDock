WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_orderdate,
        lo.lo_commitdate,
        CAST(od.d_date AS DATE)        AS order_date,
        od.d_year                     AS order_year,
        od.d_month                    AS order_month
    FROM lineorder lo
    JOIN dim_date od
      ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
),
commit_info AS (
    SELECT
        lo.lo_orderkey,
        CAST(cd.d_date AS DATE) AS commit_date,
        cd.d_year                AS commit_year
    FROM lineorder lo
    JOIN dim_date cd
      ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
)
SELECT
    oi.order_year,
    cust.c_region,
    part.p_category,
    SUM(oi.lo_revenue)                         AS total_revenue,
    COUNT(DISTINCT oi.lo_orderkey)            AS num_orders,
    AVG(oi.lo_quantity)                       AS avg_quantity,
    AVG(date_diff('day', oi.order_date, ci.commit_date)) AS avg_delay_days
FROM order_info oi
JOIN commit_info ci
  ON oi.lo_orderkey = ci.lo_orderkey
JOIN customer cust
  ON oi.lo_custkey = cust.c_custkey
JOIN part
  ON oi.lo_partkey = part.p_partkey
JOIN supplier sup
  ON oi.lo_suppkey = sup.s_suppkey
WHERE oi.order_year = '1995'
GROUP BY oi.order_year, cust.c_region, part.p_category
HAVING SUM(oi.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100
