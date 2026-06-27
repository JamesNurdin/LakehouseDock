WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        p.p_category,
        c.c_region,
        s.s_nation
    FROM lineorder lo
    JOIN dim_date d_order ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
)
SELECT
    order_year,
    commit_year,
    p_category,
    c_region,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_cnt
FROM lo_joined
GROUP BY order_year, commit_year, p_category, c_region, s_nation
ORDER BY total_profit DESC
LIMIT 10
