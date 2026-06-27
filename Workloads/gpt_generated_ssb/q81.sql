WITH lo_part AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_commitdate,
        lo.lo_shipmode,
        p.p_category,
        p.p_brand1,
        p.p_type,
        p.p_color,
        p.p_size,
        p.p_container
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#12'
)
SELECT
    agg.p_category,
    agg.p_brand1,
    agg.revenue_after_discount,
    agg.total_quantity,
    agg.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY agg.p_category ORDER BY agg.revenue_after_discount DESC) AS brand_rank
FROM (
    SELECT
        p_category,
        p_brand1,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS revenue_after_discount,
        SUM(lo_quantity) AS total_quantity,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM lo_part
    GROUP BY p_category, p_brand1
) agg
ORDER BY agg.p_category, brand_rank
LIMIT 5
