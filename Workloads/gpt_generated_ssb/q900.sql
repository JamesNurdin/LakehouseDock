WITH order_data AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        d_order.d_year,
        d_order.d_month,
        p.p_category,
        s.s_region,
        (lo.lo_revenue - lo.lo_supplycost) AS profit,
        date_diff('day', CAST(d_order.d_date AS DATE), CAST(d_commit.d_date AS DATE)) AS lead_time_days
    FROM lineorder lo
    JOIN dim_date d_order   ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit  ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN part p             ON lo.lo_partkey = p.p_partkey
    JOIN supplier s         ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c         ON lo.lo_custkey = c.c_custkey
    WHERE d_order.d_year = '1997'
)
SELECT
    d_year,
    d_month,
    p_category,
    s_region,
    SUM(profit)                AS total_profit,
    SUM(lo_revenue)            AS total_revenue,
    AVG(lo_discount)           AS avg_discount,
    AVG(lead_time_days)        AS avg_lead_time_days,
    COUNT(*)                   AS order_cnt
FROM order_data
GROUP BY d_year, d_month, p_category, s_region
ORDER BY total_profit DESC
LIMIT 10
