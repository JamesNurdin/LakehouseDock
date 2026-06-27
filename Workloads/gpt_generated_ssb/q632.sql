WITH order_dates AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1997'
),
commit_dates AS (
    SELECT d_datekey, d_year AS commit_year
    FROM dim_date
    WHERE d_year = '1997'
),
filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        cd.commit_year,
        p.p_category,
        s.s_region,
        c.c_region AS c_region,
        c.c_mktsegment
    FROM lineorder lo
    JOIN order_dates od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN commit_dates cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
)
SELECT
    order_year,
    commit_year,
    s_region,
    p_category,
    c_region,
    c_mktsegment,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM filtered_orders
GROUP BY order_year, commit_year, s_region, p_category, c_region, c_mktsegment
ORDER BY total_profit DESC
LIMIT 20
