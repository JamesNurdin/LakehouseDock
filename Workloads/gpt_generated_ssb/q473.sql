WITH
order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        d_ord.d_year AS order_year,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(d_ord.d_datekey AS integer) = lo.lo_orderdate
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d_com
        ON CAST(d_com.d_datekey AS integer) = lo.lo_commitdate
    WHERE d_com.d_year = '1995'
),
agg AS (
    SELECT
        order_year,
        s_region,
        COUNT(DISTINCT lo_orderkey) AS num_orders,
        SUM(lo_quantity) AS total_quantity,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost - lo_tax) AS total_profit,
        AVG(lo_discount) AS avg_discount
    FROM order_data
    GROUP BY order_year, s_region
)
SELECT
    order_year,
    s_region,
    num_orders,
    total_quantity,
    total_revenue,
    total_profit,
    avg_discount,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY order_year, revenue_rank
