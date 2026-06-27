WITH supplier_revenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        lo.lo_shipmode,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_discount BETWEEN 0 AND 5
    GROUP BY
        s.s_suppkey,
        s.s_name,
        s.s_region,
        s.s_nation,
        lo.lo_shipmode
)
SELECT
    s_suppkey,
    s_name,
    s_region,
    s_nation,
    lo_shipmode,
    total_revenue,
    total_extendedprice,
    order_count,
    RANK() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS region_revenue_rank
FROM supplier_revenue
ORDER BY total_revenue DESC
LIMIT 100
