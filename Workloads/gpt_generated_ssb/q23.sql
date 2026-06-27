WITH supplier_metrics AS (
    SELECT
        s.s_region,
        s.s_nation,
        s.s_city,
        l.lo_shipmode,
        SUM(l.lo_revenue) AS total_revenue,
        AVG(l.lo_discount) AS avg_discount,
        COUNT(DISTINCT l.lo_orderkey) AS order_cnt,
        SUM(l.lo_extendedprice) AS total_extendedprice
    FROM lineorder AS l
    JOIN supplier AS s
        ON l.lo_suppkey = s.s_suppkey
    WHERE l.lo_quantity > 30
    GROUP BY s.s_region, s.s_nation, s.s_city, l.lo_shipmode
    HAVING SUM(l.lo_revenue) > 1000000
)
SELECT
    s_region,
    s_nation,
    s_city,
    lo_shipmode,
    total_revenue,
    avg_discount,
    order_cnt,
    total_extendedprice,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM supplier_metrics
ORDER BY total_revenue DESC
LIMIT 10
