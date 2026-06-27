WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_shipmode,
        d_ord.d_year AS order_year,
        d_com.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
)
SELECT
    od.order_year,
    s.s_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE od.order_year = '1995'
  AND od.commit_year = '1995'
  AND s.s_region = 'ASIA'
GROUP BY od.order_year, s.s_region, p.p_category
ORDER BY od.order_year, s.s_region, p.p_category
