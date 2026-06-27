WITH region_sales AS (
   SELECT
      c.c_region,
      c.c_nation,
      c.c_mktsegment,
      SUM(lo.lo_extendedprice) AS total_extendedprice,
      SUM(lo.lo_revenue)      AS total_revenue,
      AVG(lo.lo_discount)    AS avg_discount,
      COUNT(*)               AS order_count
   FROM lineorder lo
   JOIN customer c
     ON lo.lo_custkey = c.c_custkey
   WHERE c.c_region = 'ASIA'
   GROUP BY c.c_region, c.c_nation, c.c_mktsegment
)
SELECT
   rs.c_region,
   rs.c_nation,
   rs.c_mktsegment,
   rs.total_extendedprice,
   rs.total_revenue,
   rs.avg_discount,
   rs.order_count,
   ROW_NUMBER() OVER (ORDER BY rs.total_revenue DESC) AS revenue_rank,
   SUM(rs.total_revenue) OVER (
       ORDER BY rs.total_revenue DESC
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS cumulative_revenue
FROM region_sales rs
ORDER BY rs.total_revenue DESC
LIMIT 10
