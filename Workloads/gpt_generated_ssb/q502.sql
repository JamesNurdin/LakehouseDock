WITH base AS (
    SELECT
        d.d_year,
        s.s_region,
        p.p_category,
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1995'
),
agg AS (
    SELECT
        d_year,
        s_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_count,
        COUNT(DISTINCT lo_custkey) AS customer_count
    FROM base
    GROUP BY d_year, s_region, p_category
),
ranked AS (
    SELECT
        d_year,
        s_region,
        p_category,
        total_revenue,
        total_profit,
        total_quantity,
        avg_discount,
        order_count,
        customer_count,
        ROW_NUMBER() OVER (PARTITION BY d_year, s_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM agg
)
SELECT
    d_year,
    s_region,
    p_category,
    total_revenue,
    total_profit,
    total_quantity,
    avg_discount,
    order_count,
    customer_count
FROM ranked
WHERE revenue_rank <= 5
ORDER BY d_year, s_region, revenue_rank
