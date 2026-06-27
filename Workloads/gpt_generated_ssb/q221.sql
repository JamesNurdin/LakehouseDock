WITH profit_by_supplier_brand AS (
    SELECT
        d.d_year,
        s.s_region,
        p.p_brand1,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1995'
    GROUP BY d.d_year, s.s_region, p.p_brand1
)
SELECT
    pb.d_year,
    pb.s_region,
    pb.p_brand1,
    pb.total_revenue,
    pb.total_profit,
    pb.order_count,
    ROW_NUMBER() OVER (PARTITION BY pb.s_region ORDER BY pb.total_profit DESC) AS profit_rank
FROM profit_by_supplier_brand pb
WHERE pb.total_profit > 0
ORDER BY pb.s_region, profit_rank
LIMIT 50
