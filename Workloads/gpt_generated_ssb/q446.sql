WITH order_data AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_orderdate,
        d_order.d_year AS order_year,
        c.c_region,
        p.p_category,
        d_order.d_date AS order_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
order_agg AS (
    SELECT
        order_year,
        p_category,
        c_region,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_custkey) AS distinct_customers
    FROM order_data
    GROUP BY order_year, p_category, c_region
)
SELECT
    order_year,
    p_category,
    c_region,
    total_revenue,
    avg_discount,
    distinct_customers,
    total_revenue / SUM(total_revenue) OVER (PARTITION BY order_year) AS revenue_share
FROM order_agg
ORDER BY total_revenue DESC
LIMIT 20
