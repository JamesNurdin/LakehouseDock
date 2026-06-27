WITH regional_sales AS (
    SELECT
        c_region,
        c_nation,
        lo_shipmode,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_count
    FROM lineorder
    JOIN customer ON lineorder.lo_custkey = customer.c_custkey
    WHERE c_region IN ('ASIA', 'EUROPE')
    GROUP BY c_region, c_nation, lo_shipmode
)
SELECT
    c_region,
    c_nation,
    lo_shipmode,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM regional_sales
ORDER BY total_profit DESC
LIMIT 10
