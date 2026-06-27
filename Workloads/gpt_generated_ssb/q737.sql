WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date,
        date_diff('day', CAST(d_order.d_date AS date), CAST(d_commit.d_date AS date)) AS lead_days
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
),
revenue_by_region_year AS (
    SELECT
        c.c_region,
        p.p_category,
        od.order_year,
        SUM(od.lo_revenue) AS total_revenue,
        SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
        AVG(od.lo_discount) AS avg_discount,
        AVG(od.lead_days) AS avg_lead_days,
        COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
    FROM order_dates od
    JOIN customer c
        ON od.lo_custkey = c.c_custkey
    JOIN part p
        ON od.lo_partkey = p.p_partkey
    JOIN supplier s
        ON od.lo_suppkey = s.s_suppkey
    WHERE c.c_region = 'AMERICA'
      AND p.p_category = 'MFGR#1'
    GROUP BY
        c.c_region,
        p.p_category,
        od.order_year
)
SELECT
    c_region,
    p_category,
    order_year,
    total_revenue,
    total_profit,
    avg_discount,
    avg_lead_days,
    distinct_orders,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_year
ORDER BY revenue_rank
LIMIT 10
