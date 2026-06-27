WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
      AND d_commit.d_year >= '1995'
),
aggregated AS (
    SELECT
        s_region,
        p_category,
        order_year,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM order_details
    GROUP BY s_region, p_category, order_year
)
SELECT
    s_region,
    p_category,
    order_year,
    total_revenue,
    total_profit,
    avg_discount,
    distinct_orders,
    SUM(total_revenue) OVER (PARTITION BY s_region ORDER BY order_year) AS cumulative_revenue
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 20
