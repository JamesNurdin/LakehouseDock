WITH lo_agg AS (
    SELECT
        lo_partkey,
        sum(lo_revenue) AS revenue,
        sum(lo_quantity) AS quantity,
        sum(lo_extendedprice) AS extendedprice,
        avg(lo_discount) AS avg_discount,
        count(DISTINCT lo_orderkey) AS distinct_orders
    FROM lineorder
    WHERE lo_quantity > 5
    GROUP BY lo_partkey
)
SELECT
    p.p_category,
    p.p_brand1,
    p.p_name,
    lo_agg.revenue,
    lo_agg.quantity,
    lo_agg.extendedprice,
    lo_agg.avg_discount,
    lo_agg.distinct_orders,
    row_number() OVER (PARTITION BY p.p_category ORDER BY lo_agg.revenue DESC) AS revenue_rank
FROM lo_agg
JOIN part p
    ON lo_agg.lo_partkey = p.p_partkey
WHERE p.p_size >= 10
  AND p.p_container = 'SM BOX'
ORDER BY p.p_category, revenue_rank
LIMIT 100
