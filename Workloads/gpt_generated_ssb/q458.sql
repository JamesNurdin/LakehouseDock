WITH profit_by_line AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        (lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS profit
    FROM lineorder lo
    WHERE lo.lo_discount > 5
),
profit_agg AS (
    SELECT
        c.c_region AS c_region,
        p.p_category AS p_category,
        s.s_nation AS s_nation,
        SUM(pbl.profit) AS total_profit,
        AVG(pbl.lo_discount) AS avg_discount,
        COUNT(DISTINCT pbl.lo_orderkey) AS order_cnt
    FROM profit_by_line pbl
    JOIN customer c ON pbl.lo_custkey = c.c_custkey
    JOIN part p ON pbl.lo_partkey = p.p_partkey
    JOIN supplier s ON pbl.lo_suppkey = s.s_suppkey
    GROUP BY c.c_region, p.p_category, s.s_nation
)
SELECT
    pa.c_region,
    pa.p_category,
    pa.s_nation,
    pa.total_profit,
    pa.avg_discount,
    pa.order_cnt,
    RANK() OVER (PARTITION BY pa.c_region ORDER BY pa.total_profit DESC) AS region_profit_rank
FROM profit_agg pa
WHERE pa.total_profit > 0
ORDER BY pa.c_region, region_profit_rank
LIMIT 50
