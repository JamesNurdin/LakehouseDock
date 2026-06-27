WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_shipmode,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
      ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
      ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1995'
)
SELECT
    c.c_region,
    od.order_year,
    p.p_category,
    s.s_region AS supplier_region,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    MIN(od.commit_year) AS earliest_commit_year,
    MAX(od.commit_year) AS latest_commit_year
FROM order_data od
JOIN customer c
  ON od.lo_custkey = c.c_custkey
JOIN part p
  ON od.lo_partkey = p.p_partkey
JOIN supplier s
  ON od.lo_suppkey = s.s_suppkey
WHERE od.lo_shipmode = 'AIR'
GROUP BY c.c_region, od.order_year, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 100
