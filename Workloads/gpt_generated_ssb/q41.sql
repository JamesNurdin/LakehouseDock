WITH customer_revenue AS (
    SELECT
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        c.c_custkey,
        c.c_name,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_shipmode = 'AIR'
      AND lo.lo_orderpriority = '1-URGENT'
    GROUP BY
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        c.c_custkey,
        c.c_name
)
SELECT
    cr.c_region,
    cr.c_nation,
    cr.c_mktsegment,
    cr.c_custkey,
    cr.c_name,
    cr.total_revenue,
    cr.avg_discount,
    cr.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY cr.c_region, cr.c_mktsegment ORDER BY cr.total_revenue DESC) AS region_mktsegment_rank
FROM customer_revenue cr
WHERE cr.total_revenue > 1000000
ORDER BY cr.c_region, cr.c_mktsegment, region_mktsegment_rank
