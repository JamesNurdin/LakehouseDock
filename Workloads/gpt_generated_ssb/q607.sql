WITH order_dates AS (
    SELECT 
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_year AS order_year,
        cd.d_year AS commit_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od 
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd 
        ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
)
SELECT 
    od.order_year,
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c 
    ON od.lo_custkey = c.c_custkey
JOIN part p 
    ON od.lo_partkey = p.p_partkey
JOIN supplier s 
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1995'
  AND od.commit_year = '1995'
  AND p.p_category = 'MFGR#12'
  AND od.lo_shipmode = 'AIR'
GROUP BY od.order_year, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20
