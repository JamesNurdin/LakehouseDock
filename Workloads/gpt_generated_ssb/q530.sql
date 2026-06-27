WITH order_dates AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        c.c_region,
        s.s_region,
        p.p_brand1,
        p.p_category,
        d_order.d_year,
        d_order.d_datekey AS order_date_key,
        d_commit.d_datekey AS commit_date_key
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    WHERE p.p_category = 'MFGR#12'
      AND d_order.d_year = '1997'
)
SELECT
    c_region AS customer_region,
    s_region AS supplier_region,
    d_year AS order_year,
    p_brand1 AS brand,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(CAST(commit_date_key AS integer) - CAST(order_date_key AS integer)) AS avg_order_to_commit_days
FROM order_dates
GROUP BY
    c_region,
    s_region,
    d_year,
    p_brand1
ORDER BY total_profit DESC
LIMIT 100
