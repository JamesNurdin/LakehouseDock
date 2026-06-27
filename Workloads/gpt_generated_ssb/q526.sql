WITH lo AS (
    -- Filter the lineorder table early to reduce the data volume
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_discount,
        lo_shipmode
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
),
joined AS (
    -- Join all dimension tables using the allowed join keys
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        c.c_region               AS cust_region,
        p.p_category,
        s.s_region               AS supp_region,
        od.d_year                AS order_year,
        od.d_date                AS order_date,
        cd.d_date                AS commit_date
    FROM lo
    JOIN customer c   ON lo.lo_custkey = c.c_custkey
    JOIN part     p   ON lo.lo_partkey = p.p_partkey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od  ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd  ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
),
agg AS (
    -- Aggregate metrics per year, customer region, supplier region and product category
    SELECT
        order_year,
        cust_region,
        supp_region,
        p_category,
        SUM(lo_revenue)                                      AS total_revenue,
        AVG(lo_discount)                                      AS avg_discount,
        COUNT(DISTINCT lo_orderkey)                           AS num_orders,
        AVG(date_diff('day', CAST(commit_date AS date), CAST(order_date AS date))) AS avg_lead_time_days
    FROM joined
    GROUP BY order_year, cust_region, supp_region, p_category
    HAVING SUM(lo_revenue) > 500000
)
SELECT
    order_year,
    cust_region,
    supp_region,
    p_category,
    total_revenue,
    avg_discount,
    num_orders,
    avg_lead_time_days,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 20
