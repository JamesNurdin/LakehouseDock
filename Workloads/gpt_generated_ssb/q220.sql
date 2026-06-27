WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_shipmode,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
      ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
)
SELECT
    od.d_year AS order_year,
    s.s_region,
    SUM(od.lo_extendedprice) AS total_extended_price,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dim od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#1'
  AND s.s_region = 'AMERICA'
  AND od.lo_shipmode = 'AIR'
GROUP BY od.d_year, s.s_region
ORDER BY od.d_year, s.s_region
