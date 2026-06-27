WITH aggregated AS (
    SELECT
        p.p_category,
        d.d_yearmonth,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
      AND d.d_year = '1995'
    GROUP BY p.p_category, d.d_yearmonth
)
SELECT
    p_category,
    d_yearmonth,
    total_revenue,
    total_profit,
    order_count,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_yearmonth ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY d_yearmonth, revenue_rank
LIMIT 50
