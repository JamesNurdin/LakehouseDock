/*
  Analytical query for the SSB schema (Trino/ Iceberg).
  It shows, for each supplier region and order year, the top‑3 part categories by revenue.
  The query demonstrates joins, filters, grouping, aggregation, a window function and ordering.
*/
WITH
  -- Pull the necessary columns from the fact table and all dimension tables
  order_data AS (
    SELECT
      lo.lo_orderkey,
      lo.lo_custkey,
      lo.lo_partkey,
      lo.lo_suppkey,
      lo.lo_orderdate,
      lo.lo_commitdate,
      lo.lo_extendedprice,
      lo.lo_revenue,
      lo.lo_supplycost,
      lo.lo_discount,
      lo.lo_quantity,
      lo.lo_tax,
      lo.lo_shipmode,
      c.c_region               AS cust_region,
      c.c_nation               AS cust_nation,
      p.p_category             AS p_category,
      p.p_brand1               AS p_brand1,
      s.s_region               AS supp_region,
      s.s_nation               AS supp_nation,
      d.d_year                 AS d_year,
      d.d_date                 AS d_date
    FROM lineorder lo
    JOIN customer c   ON lo.lo_custkey = c.c_custkey
    JOIN part     p   ON lo.lo_partkey = p.p_partkey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d   ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year BETWEEN '1997' AND '1998'
  ),

  -- Aggregate revenue and other metrics per supplier‑region / year / part‑category
  category_agg AS (
    SELECT
      od.supp_region,
      od.d_year,
      od.p_category,
      SUM(od.lo_revenue)                         AS revenue,
      SUM(od.lo_supplycost)                      AS supply_cost,
      SUM(od.lo_revenue - od.lo_supplycost)      AS profit,
      AVG(od.lo_discount)                        AS avg_discount,
      COUNT(DISTINCT od.lo_orderkey)             AS orders
    FROM order_data od
    GROUP BY od.supp_region, od.d_year, od.p_category
  ),

  -- Rank categories within each region‑year by revenue
  ranked_category AS (
    SELECT
      ca.supp_region,
      ca.d_year,
      ca.p_category,
      ca.revenue,
      ca.supply_cost,
      ca.profit,
      ca.avg_discount,
      ca.orders,
      ROW_NUMBER() OVER (PARTITION BY ca.supp_region, ca.d_year ORDER BY ca.revenue DESC) AS rn
    FROM category_agg ca
  )

SELECT
  rc.supp_region,
  rc.d_year,
  rc.p_category,
  rc.revenue,
  rc.supply_cost,
  rc.profit,
  rc.avg_discount,
  rc.orders
FROM ranked_category rc
WHERE rc.rn <= 3
ORDER BY rc.supp_region, rc.d_year, rc.revenue DESC
