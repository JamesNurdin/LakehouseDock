WITH order_filtered AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_supplycost
    FROM lineorder lo
),
joined AS (
    SELECT
        s.s_region,
        p.p_category,
        d_order.d_year,
        d_order.d_month,
        f.lo_orderkey,
        f.lo_revenue,
        f.lo_supplycost
    FROM order_filtered f
    JOIN dim_date d_order
        ON CAST(f.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(f.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN customer c
        ON f.lo_custkey = c.c_custkey
    JOIN part p
        ON f.lo_partkey = p.p_partkey
    JOIN supplier s
        ON f.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1997'
),
aggregated AS (
    SELECT
        s_region,
        p_category,
        d_year,
        d_month,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS profit,
        COUNT(DISTINCT lo_orderkey) AS order_cnt
    FROM joined
    GROUP BY s_region, p_category, d_year, d_month
)
SELECT
    s_region,
    p_category,
    d_year,
    d_month,
    total_revenue,
    total_supplycost,
    profit,
    order_cnt,
    RANK() OVER (PARTITION BY s_region ORDER BY profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit DESC
LIMIT 100
