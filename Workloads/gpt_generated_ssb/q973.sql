WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        cd.d_date AS commit_date,
        c.c_region,
        c.c_mktsegment,
        p.p_category,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
),
agg AS (
    SELECT
        order_year,
        s_nation,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_count,
        COUNT(DISTINCT lo_custkey) AS distinct_customer_count
    FROM lo_joined
    GROUP BY order_year, s_nation, p_category
),
ranked AS (
    SELECT
        order_year,
        s_nation,
        p_category,
        total_revenue,
        total_profit,
        avg_discount,
        order_count,
        distinct_customer_count,
        ROW_NUMBER() OVER (PARTITION BY order_year, s_nation ORDER BY total_revenue DESC) AS category_rank
    FROM agg
)
SELECT
    order_year,
    s_nation,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    distinct_customer_count,
    category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY order_year, s_nation, total_revenue DESC
LIMIT 100
