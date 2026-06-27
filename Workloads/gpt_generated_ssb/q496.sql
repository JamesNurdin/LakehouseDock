WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#1'
),
aggregated AS (
    SELECT
        supplier_region,
        order_year,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit
    FROM filtered_orders
    GROUP BY supplier_region, order_year
)
SELECT
    supplier_region,
    order_year,
    total_revenue,
    total_supplycost,
    total_profit,
    total_profit * 100.0 / SUM(total_profit) OVER (PARTITION BY order_year) AS profit_pct_of_year
FROM aggregated
ORDER BY total_profit DESC
LIMIT 10
