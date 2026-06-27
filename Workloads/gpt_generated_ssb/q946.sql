WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        CAST(lo.lo_orderdate AS VARCHAR) AS order_datekey,
        CAST(lo.lo_commitdate AS VARCHAR) AS commit_datekey,
        c.c_region,
        s.s_region,
        p.p_category,
        d_ord.d_year AS order_year,
        d_com.d_year AS commit_year
    FROM lineorder AS lo
    JOIN dim_date AS d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date AS d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
    JOIN customer AS c
        ON lo.lo_custkey = c.c_custkey
    JOIN part AS p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier AS s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_ord.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND d_com.d_year >= d_ord.d_year
),
agg AS (
    SELECT
        order_year,
        c_region,
        s_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM order_data
    GROUP BY order_year, c_region, s_region, p_category
)
SELECT
    order_year,
    c_region,
    s_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    distinct_orders,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank_by_category
FROM agg
ORDER BY order_year, total_revenue DESC
