WITH base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        p.p_category,
        p.p_brand1,
        s.s_region,
        s.s_nation,
        c.c_region AS customer_region,
        c.c_mktsegment
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d_order.d_year = '1995'
      AND s.s_region = 'ASIA'
      AND p.p_category = 'MFGR#12'
),
agg AS (
    SELECT
        order_year,
        order_month,
        p_category,
        s_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM base
    GROUP BY order_year, order_month, p_category, s_region
)
SELECT
    order_year,
    order_month,
    p_category,
    s_region,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY order_year, order_month ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
