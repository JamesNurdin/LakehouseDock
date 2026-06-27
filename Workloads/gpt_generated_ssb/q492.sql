WITH filtered_lineorder AS (
    SELECT lo.lo_orderkey,
           lo.lo_linenumber,
           lo.lo_custkey,
           lo.lo_partkey,
           lo.lo_suppkey,
           lo.lo_orderdate,
           lo.lo_commitdate,
           lo.lo_revenue,
           lo.lo_supplycost,
           lo.lo_discount
    FROM lineorder lo
    JOIN dim_date cd
      ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE CAST(cd.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT od.d_year AS order_year,
       c.c_region AS cust_region,
       p.p_category AS part_category,
       s.s_region AS supp_region,
       SUM(fl.lo_revenue) AS total_revenue,
       SUM(fl.lo_supplycost) AS total_supplycost,
       SUM(fl.lo_revenue - fl.lo_supplycost) AS total_profit,
       AVG(fl.lo_discount) AS avg_discount
FROM filtered_lineorder fl
JOIN dim_date od
  ON CAST(fl.lo_orderdate AS varchar) = od.d_datekey
JOIN customer c
  ON fl.lo_custkey = c.c_custkey
JOIN part p
  ON fl.lo_partkey = p.p_partkey
JOIN supplier s
  ON fl.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
