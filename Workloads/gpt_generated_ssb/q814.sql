WITH filtered_orders AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_extendedprice,
        lo.lo_supplycost,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    WHERE CAST(d_order.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
joined_data AS (
    SELECT
        lo.lo_extendedprice,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region,
        p.p_category
    FROM filtered_orders lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
),
aggregated AS (
    SELECT
        c_region,
        p_category,
        SUM(lo_extendedprice) AS total_revenue,
        SUM(lo_extendedprice - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount
    FROM joined_data
    GROUP BY c_region, p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY c_region, revenue_rank
