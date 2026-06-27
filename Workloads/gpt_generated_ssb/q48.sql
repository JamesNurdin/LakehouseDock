WITH base AS (
   SELECT
       lo.lo_orderkey,
       lo.lo_custkey,
       lo.lo_partkey,
       lo.lo_suppkey,
       lo.lo_extendedprice,
       lo.lo_discount,
       lo.lo_revenue,
       lo.lo_supplycost,
       od.d_year,
       c.c_region,
       p.p_category,
       s.s_name
   FROM lineorder lo
   JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
   JOIN customer c   ON lo.lo_custkey = c.c_custkey
   JOIN part p       ON lo.lo_partkey = p.p_partkey
   JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
   WHERE od.d_year = '1995'
),
agg AS (
   SELECT
       b.d_year,
       b.c_region,
       b.p_category,
       SUM(b.lo_revenue)   AS total_revenue,
       SUM(b.lo_supplycost) AS total_supplycost,
       SUM(b.lo_revenue) - SUM(b.lo_supplycost) AS total_profit
   FROM base b
   GROUP BY b.d_year, b.c_region, b.p_category
),
supplier_profit AS (
   SELECT
       b.d_year,
       b.p_category,
       b.s_name,
       SUM(b.lo_revenue) - SUM(b.lo_supplycost) AS supplier_profit,
       ROW_NUMBER() OVER (
           PARTITION BY b.d_year, b.p_category
           ORDER BY SUM(b.lo_revenue) - SUM(b.lo_supplycost) DESC
       ) AS profit_rank
   FROM base b
   GROUP BY b.d_year, b.p_category, b.s_name
)
SELECT
   a.d_year,
   a.c_region,
   a.p_category,
   a.total_revenue,
   a.total_profit,
   CAST(a.total_profit AS double) / NULLIF(a.total_revenue, 0) AS profit_ratio,
   sp.s_name        AS top_supplier,
   sp.supplier_profit,
   sp.profit_rank
FROM agg a
JOIN supplier_profit sp
  ON a.d_year    = sp.d_year
 AND a.p_category = sp.p_category
WHERE sp.profit_rank <= 3
ORDER BY a.d_year, a.p_category, sp.profit_rank
