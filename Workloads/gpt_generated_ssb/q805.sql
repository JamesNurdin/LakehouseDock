WITH supplier_metrics AS (
    SELECT
        s.s_region AS s_region,
        s.s_name   AS s_name,
        SUM(lo.lo_revenue)      AS total_revenue,
        SUM(lo.lo_supplycost)   AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
        COUNT(*)                AS line_count,
        AVG(lo.lo_discount)     AS avg_discount
    FROM lineorder lo
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
    GROUP BY s.s_region, s.s_name
),
ranked_suppliers AS (
    SELECT
        s_region,
        s_name,
        total_revenue,
        total_supplycost,
        total_profit,
        line_count,
        avg_discount,
        total_profit * 1.0 / total_revenue AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY total_profit DESC) AS profit_rank
    FROM supplier_metrics
)
SELECT
    s_region,
    s_name,
    total_revenue,
    total_supplycost,
    total_profit,
    line_count,
    avg_discount,
    profit_margin,
    profit_rank
FROM ranked_suppliers
WHERE profit_rank <= 5
ORDER BY s_region, profit_rank
