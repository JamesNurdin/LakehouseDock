WITH revenue_by_region_category AS (
    SELECT
        cust.c_region,
        part.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_extendedprice) AS total_extended_price,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS lineitem_count,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_order_count
    FROM lineorder lo
    JOIN customer cust
        ON lo.lo_custkey = cust.c_custkey
    JOIN part part
        ON lo.lo_partkey = part.p_partkey
    WHERE
        cust.c_region = 'ASIA'
        AND part.p_size > 10
        AND lo.lo_quantity > 30
        AND lo.lo_discount < 5
    GROUP BY cust.c_region, part.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_extended_price,
    avg_discount,
    lineitem_count,
    distinct_order_count,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_category
ORDER BY total_revenue DESC
LIMIT 10
