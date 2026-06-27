WITH profit_by_region_brand AS (
    SELECT
        s.s_region,
        p.p_brand1,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY s.s_region, p.p_brand1
)
SELECT
    s_region,
    p_brand1,
    total_revenue,
    total_supplycost,
    total_profit,
    RANK() OVER (PARTITION BY s_region ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_region_brand
ORDER BY s_region, profit_rank
LIMIT 20
