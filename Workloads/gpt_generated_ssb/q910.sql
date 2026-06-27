WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_date AS order_date,
        d_order.d_year AS order_year,
        d_commit.d_date AS commit_date,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category,
    od.order_year,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit
FROM order_dim od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
WHERE CAST(od.order_date AS DATE) >= DATE '1995-01-01'
  AND CAST(od.order_date AS DATE) < DATE '1996-01-01'
  AND c.c_region = 'ASIA'
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    od.order_year
ORDER BY total_revenue DESC
LIMIT 10
