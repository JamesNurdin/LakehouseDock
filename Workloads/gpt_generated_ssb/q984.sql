WITH order_data AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date,
        c.c_region,
        s.s_region AS supplier_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year BETWEEN '1993' AND '1997'
      AND lo.lo_shipmode = 'AIR'
),
aggregated AS (
    SELECT
        order_year,
        c_region,
        supplier_region,
        p_category,
        COUNT(*) AS order_count,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        AVG(date_diff('day', date(commit_date), date(order_date))) AS avg_lead_days
    FROM order_data
    GROUP BY order_year, c_region, supplier_region, p_category
)
SELECT
    order_year,
    c_region,
    supplier_region,
    p_category,
    order_count,
    total_revenue,
    avg_discount,
    avg_lead_days,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY order_year, revenue_rank
LIMIT 30
