WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_commitdate,
        lo.lo_shipmode,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
      ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year IN ('1997', '1998')
)
SELECT
    od.d_year AS year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    SUM(od.lo_quantity) AS total_quantity,
    (SUM(od.lo_revenue - od.lo_supplycost) / SUM(od.lo_revenue)) * 100 AS profit_margin_percent
FROM order_dates od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
