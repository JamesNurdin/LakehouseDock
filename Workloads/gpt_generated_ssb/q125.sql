WITH order_data AS (
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
        lo.lo_ordertotalprice,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    WHERE d_order.d_year = '1997'
)
SELECT
    c.c_region,
    p.p_category,
    o.order_year,
    o.commit_year,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS distinct_orders
FROM order_data o
JOIN customer c ON o.lo_custkey = c.c_custkey
JOIN part p ON o.lo_partkey = p.p_partkey
JOIN supplier s ON o.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12' AND s.s_region = 'ASIA'
GROUP BY c.c_region, p.p_category, o.order_year, o.commit_year
ORDER BY total_revenue DESC
LIMIT 10
