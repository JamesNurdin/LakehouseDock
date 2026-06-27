WITH region_supplier_metrics AS (
    SELECT
        s.s_region,
        s.s_name,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
    GROUP BY s.s_region, s.s_name
)
SELECT
    s_region,
    s_name,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY total_profit DESC) AS profit_rank
FROM region_supplier_metrics
WHERE total_profit > 500000
ORDER BY s_region, profit_rank
