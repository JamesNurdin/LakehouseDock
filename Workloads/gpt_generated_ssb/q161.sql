/* Revenue and profit analysis by month and supplier region for 1995 orders of category MFGR#12 */
WITH filtered AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d.d_yearmonth,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#12'
),
agg AS (
    SELECT
        f.d_yearmonth,
        f.s_region,
        SUM(f.lo_revenue) AS total_revenue,
        SUM(f.lo_revenue) - SUM(f.lo_supplycost) AS total_profit,
        AVG(f.lo_discount) AS avg_discount,
        COUNT(DISTINCT f.lo_custkey) AS distinct_customers
    FROM filtered f
    GROUP BY f.d_yearmonth, f.s_region
)
SELECT
    a.d_yearmonth,
    a.s_region,
    a.total_revenue,
    a.total_profit,
    a.avg_discount,
    a.distinct_customers,
    SUM(a.total_revenue) OVER (
        PARTITION BY a.s_region
        ORDER BY a.d_yearmonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_region
FROM agg a
ORDER BY a.total_revenue DESC
LIMIT 10
