WITH lineorder_profit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
),
agg AS (
    SELECT
        p.p_brand1,
        s.s_region,
        SUM(lp.profit) AS total_profit,
        SUM(lp.lo_quantity) AS total_quantity,
        AVG(lp.lo_discount) AS avg_discount
    FROM lineorder_profit lp
    JOIN part p
        ON lp.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lp.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#1'
      AND s.s_region = 'AMERICA'
    GROUP BY p.p_brand1, s.s_region
    HAVING SUM(lp.profit) > 0
)
SELECT
    a.p_brand1,
    a.s_region,
    a.total_profit,
    a.total_quantity,
    a.avg_discount,
    ROW_NUMBER() OVER (PARTITION BY a.s_region ORDER BY a.total_profit DESC) AS region_rank
FROM agg a
ORDER BY a.total_profit DESC
