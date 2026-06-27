WITH agg AS (
    SELECT
        part.p_category,
        part.p_brand1,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        sum(lo.lo_quantity) AS total_quantity,
        avg(lo.lo_discount) AS avg_discount,
        count(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    GROUP BY
        part.p_category,
        part.p_brand1
)
SELECT
    agg.p_category,
    agg.p_brand1,
    agg.total_revenue,
    agg.total_profit,
    agg.total_quantity,
    agg.avg_discount,
    agg.order_count,
    row_number() OVER (PARTITION BY agg.p_category ORDER BY agg.total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY agg.total_revenue DESC
LIMIT 20
