WITH lineorder_profit AS (
    SELECT
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    WHERE lo.lo_discount > 0
),
region_segment_agg AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        sum(lop.lo_revenue) AS total_revenue,
        sum(lop.profit) AS total_profit,
        avg(lop.lo_discount) AS avg_discount,
        sum(lop.lo_quantity) AS total_quantity,
        count(distinct c.c_custkey) AS distinct_customers
    FROM lineorder_profit lop
    JOIN customer c ON lop.lo_custkey = c.c_custkey
    GROUP BY c.c_region, c.c_mktsegment
)
SELECT
    rsa.c_region,
    rsa.c_mktsegment,
    rsa.total_revenue,
    rsa.total_profit,
    rsa.avg_discount,
    rsa.total_quantity,
    rsa.distinct_customers,
    row_number() OVER (PARTITION BY rsa.c_region ORDER BY rsa.total_revenue DESC) AS region_segment_rank
FROM region_segment_agg rsa
ORDER BY rsa.total_revenue DESC
LIMIT 20
