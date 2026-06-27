WITH agg AS (
    SELECT
        d_order.d_year AS order_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        AVG(lo.lo_discount) AS avg_discount,
        AVG(lo.lo_commitdate - lo.lo_orderdate) AS avg_delay_days
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_order.d_year = '1995'
    GROUP BY d_order.d_year, p.p_category
)
SELECT
    order_year,
    p_category,
    total_revenue,
    total_extendedprice,
    avg_discount,
    avg_delay_days,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY order_year, revenue_rank
LIMIT 20
