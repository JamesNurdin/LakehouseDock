WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_month AS order_month,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
)
SELECT
    od.order_year,
    c.c_region,
    s.s_region AS supplier_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supply_cost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders,
    AVG(od.lo_discount) AS avg_discount
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE od.order_year BETWEEN '1992' AND '1997'
  AND p.p_category = 'MFGR#12'
GROUP BY od.order_year, c.c_region, s.s_region, p.p_category
ORDER BY od.order_year, c.c_region, s.s_region
