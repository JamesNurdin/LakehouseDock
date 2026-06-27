WITH lo_agg AS (
    SELECT
        lo_suppkey,
        sum(lo_revenue) AS total_revenue,
        sum(lo_supplycost) AS total_supplycost,
        sum(lo_quantity) AS total_quantity,
        avg(lo_discount) AS avg_discount,
        count(DISTINCT lo_orderkey) AS order_cnt
    FROM lineorder
    WHERE lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY lo_suppkey
)
SELECT
    s.s_region,
    s.s_name,
    s.s_city,
    lo_agg.total_revenue,
    lo_agg.total_supplycost,
    (lo_agg.total_revenue - lo_agg.total_supplycost) AS profit,
    lo_agg.total_quantity,
    lo_agg.avg_discount,
    lo_agg.order_cnt,
    rank() OVER (
        PARTITION BY s.s_region
        ORDER BY (lo_agg.total_revenue - lo_agg.total_supplycost) DESC
    ) AS region_rank
FROM lo_agg
JOIN supplier s
    ON lo_agg.lo_suppkey = s.s_suppkey
ORDER BY s.s_region, region_rank
LIMIT 20
