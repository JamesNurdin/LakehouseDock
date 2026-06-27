WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d.d_year,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1995'
),
aggregated AS (
    SELECT
        d_year,
        p_category,
        s_region,
        SUM(lo_extendedprice) AS total_extended_price,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
        COUNT(DISTINCT lo_orderkey) AS num_orders
    FROM order_details
    GROUP BY d_year, p_category, s_region
)
SELECT
    d_year,
    p_category,
    s_region,
    total_extended_price,
    total_revenue,
    total_profit,
    num_orders,
    RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY d_year, revenue_rank
LIMIT 20
