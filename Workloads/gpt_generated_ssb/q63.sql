WITH lo_agg AS (
    SELECT
        lo_custkey,
        sum(lo_revenue) AS total_revenue,
        sum(lo_extendedprice) AS total_extendedprice,
        sum(lo_quantity) AS total_quantity,
        sum(lo_revenue - lo_supplycost * lo_quantity) AS total_profit,
        avg(lo_discount) AS avg_discount
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
      AND lo_orderpriority = '1-URGENT'
    GROUP BY lo_custkey
)
SELECT
    c.c_region,
    c.c_nation,
    c.c_mktsegment,
    lo_agg.total_revenue,
    lo_agg.total_extendedprice,
    lo_agg.total_quantity,
    lo_agg.total_profit,
    lo_agg.avg_discount
FROM lo_agg
JOIN customer c
    ON lo_agg.lo_custkey = c.c_custkey
ORDER BY lo_agg.total_revenue DESC
LIMIT 50
