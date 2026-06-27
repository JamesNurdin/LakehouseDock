WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        CAST(d_order.d_date AS DATE) AS order_date,
        CAST(d_commit.d_date AS DATE) AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS INTEGER)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS INTEGER)
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
)
SELECT
    oi.order_year,
    c.c_region,
    p.p_category,
    SUM(oi.lo_revenue) AS total_revenue,
    SUM(oi.lo_supplycost) AS total_supplycost,
    SUM(oi.lo_revenue - oi.lo_supplycost) AS total_profit,
    AVG(oi.lo_discount) AS avg_discount,
    AVG(date_diff('day', oi.order_date, oi.commit_date)) AS avg_lead_time_days,
    COUNT(DISTINCT oi.lo_orderkey) AS order_count
FROM order_info oi
JOIN customer c
    ON oi.lo_custkey = c.c_custkey
JOIN part p
    ON oi.lo_partkey = p.p_partkey
JOIN supplier s
    ON oi.lo_suppkey = s.s_suppkey
WHERE oi.lo_shipmode = 'AIR'
GROUP BY oi.order_year, c.c_region, p.p_category
ORDER BY oi.order_year, c.c_region, p.p_category
