WITH order_part AS (
    SELECT
        lo_orderkey,
        lo_partkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_shipmode,
        p_category,
        p_brand1,
        p_color
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE lo_quantity > 10
      AND lo_shipmode = 'AIR'
)
SELECT
    p_category,
    p_brand1,
    p_color,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_revenue) / NULLIF(SUM(lo_extendedprice), 0) AS revenue_price_ratio,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM order_part
GROUP BY p_category, p_brand1, p_color
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
