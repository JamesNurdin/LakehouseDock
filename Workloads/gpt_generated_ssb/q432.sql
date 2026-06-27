WITH lo_ps AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 20
      AND lo.lo_discount < 5
      AND s.s_region = 'EUROPE'
),
agg AS (
    SELECT
        s_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM lo_ps
    GROUP BY s_region, p_category
)
SELECT
    s_region,
    p_category,
    total_revenue,
    total_supplycost,
    total_profit,
    total_quantity,
    avg_discount,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY total_profit DESC) AS profit_rank_in_region
FROM agg
ORDER BY total_profit DESC
LIMIT 10
