WITH base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_orderdate,
        lo.lo_shipmode,
        d.d_year,
        c.c_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1997'
),
aggregated AS (
    SELECT
        d_year,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        COUNT(*) AS lineitem_cnt
    FROM base
    GROUP BY d_year, c_region, p_category
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    distinct_orders,
    lineitem_cnt,
    SUM(total_profit) OVER (
        PARTITION BY c_region
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_region
FROM aggregated
ORDER BY total_profit DESC
LIMIT 10
