WITH supplier_sales AS (
    SELECT
        s.s_region,
        s.s_nation,
        l.lo_shipmode,
        SUM(l.lo_revenue) AS total_revenue,
        SUM(l.lo_supplycost) AS total_supplycost,
        SUM(l.lo_revenue - l.lo_supplycost) AS total_profit,
        AVG(l.lo_discount) AS avg_discount,
        SUM(l.lo_quantity) AS total_quantity,
        COUNT(DISTINCT l.lo_orderkey) AS order_count
    FROM lineorder AS l
    JOIN supplier AS s
        ON l.lo_suppkey = s.s_suppkey
    WHERE l.lo_orderpriority = '1-URGENT'
      AND l.lo_shippriority >= 1
    GROUP BY s.s_region, s.s_nation, l.lo_shipmode
)
SELECT
    s_region,
    s_nation,
    lo_shipmode,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    total_quantity,
    order_count,
    RANK() OVER (PARTITION BY s_region ORDER BY total_profit DESC) AS region_profit_rank
FROM supplier_sales
ORDER BY total_profit DESC
LIMIT 20
