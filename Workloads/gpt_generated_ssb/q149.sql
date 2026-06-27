WITH lo_supp AS (
    SELECT
        lineorder.lo_orderkey,
        lineorder.lo_suppkey,
        lineorder.lo_quantity,
        lineorder.lo_extendedprice,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_discount,
        lineorder.lo_tax,
        supplier.s_region,
        supplier.s_city,
        supplier.s_name
    FROM lineorder
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE supplier.s_region = 'AMERICA'
)
SELECT
    s_region,
    s_city,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS num_orders
FROM lo_supp
GROUP BY s_region, s_city
ORDER BY total_profit DESC
LIMIT 100
