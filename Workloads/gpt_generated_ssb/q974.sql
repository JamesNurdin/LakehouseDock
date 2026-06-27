WITH order_detail AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date,
        c.c_region,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1993-01-01' AND DATE '1995-12-31'
)
SELECT
    d_year,
    c_region,
    p_category,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_lead_time_days
FROM order_detail
GROUP BY d_year, c_region, p_category, s_region
ORDER BY total_revenue DESC
LIMIT 50
