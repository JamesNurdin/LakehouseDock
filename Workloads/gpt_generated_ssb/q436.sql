WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_ordertotalprice,
        lo.lo_supplycost,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
      ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
      ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
)
SELECT
    od.order_year,
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_ordertotalprice) AS total_revenue_tax,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue) - SUM(od.lo_supplycost) AS profit,
    SUM(od.lo_ordertotalprice) - SUM(od.lo_supplycost) AS profit_after_tax,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders
FROM order_dates od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year BETWEEN '1992' AND '1997'
  AND od.lo_shipmode = 'AIR'
GROUP BY od.order_year, s.s_region, p.p_category
ORDER BY od.order_year, s.s_region, p.p_category
