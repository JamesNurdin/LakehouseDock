WITH filtered_orders AS (
    SELECT
        lo_partkey,
        lo_quantity,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_shipmode,
        lo_orderdate,
        lo_orderpriority,
        lo_orderkey
    FROM lineorder
    WHERE lo_shipmode IN ('AIR', 'AIR REG')
),
joined AS (
    SELECT
        lo_quantity,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_shipmode,
        lo_orderdate,
        lo_orderpriority,
        lo_orderkey,
        p_category,
        p_brand1,
        p_color,
        p_type,
        p_size,
        p_container
    FROM filtered_orders
    JOIN part
        ON filtered_orders.lo_partkey = part.p_partkey
    WHERE p_size BETWEEN 20 AND 30
)
SELECT
    p_category,
    p_brand1,
    p_color,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM joined
GROUP BY
    p_category,
    p_brand1,
    p_color
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10
