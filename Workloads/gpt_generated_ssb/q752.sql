WITH order_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
),
order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_shipmode,
        od.d_year AS order_year
    FROM lineorder lo
    JOIN order_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    WHERE lo.lo_shipmode = 'AIR' AND od.d_year = '1995'
)
SELECT
    od.order_year,
    c.c_region,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders
FROM order_data od
JOIN customer c ON od.lo_custkey = c.c_custkey
JOIN part p ON od.lo_partkey = p.p_partkey
JOIN supplier s ON od.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
GROUP BY od.order_year, c.c_region, p.p_category
ORDER BY od.order_year, total_revenue DESC
