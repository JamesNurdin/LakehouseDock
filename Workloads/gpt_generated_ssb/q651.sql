WITH lo_ps AS (
    SELECT
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        p.p_category,
        s.s_nation,
        s.s_region
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
),
region_category_nation AS (
    SELECT
        c.c_region,
        lo_ps.p_category,
        lo_ps.s_nation,
        SUM(lo_ps.lo_revenue) AS total_revenue,
        SUM(lo_ps.lo_supplycost) AS total_supplycost,
        SUM(lo_ps.lo_revenue) - SUM(lo_ps.lo_supplycost) AS profit,
        AVG(lo_ps.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lo_ps
    JOIN customer c ON lo_ps.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
      AND lo_ps.s_region = 'EUROPE'
    GROUP BY c.c_region, lo_ps.p_category, lo_ps.s_nation
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY profit DESC) AS profit_rank
    FROM region_category_nation
)
SELECT
    c_region,
    p_category,
    s_nation,
    total_revenue,
    total_supplycost,
    profit,
    avg_discount,
    order_count,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY c_region, profit_rank
