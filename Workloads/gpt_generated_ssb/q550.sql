WITH filtered_lo AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_shipmode,
        p.p_category,
        p.p_brand1,
        p.p_color,
        p.p_size
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity >= 30
      AND p.p_size > 10
),
agg AS (
    SELECT
        p_category,
        p_brand1,
        lo_shipmode,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_count
    FROM filtered_lo
    GROUP BY p_category, p_brand1, lo_shipmode
)
SELECT
    p_category,
    p_brand1,
    lo_shipmode,
    total_revenue,
    avg_discount,
    order_count,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 10
