WITH agg AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder AS lo
    JOIN part AS p
        ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_shipmode = 'AIR'
      AND lo.lo_orderpriority = '1-URGENT'
    GROUP BY p.p_category, p.p_brand1
)
SELECT
    p_category,
    p_brand1,
    revenue,
    total_quantity,
    avg_discount,
    order_count,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING) AS cumulative_revenue
FROM agg
ORDER BY revenue_rank
