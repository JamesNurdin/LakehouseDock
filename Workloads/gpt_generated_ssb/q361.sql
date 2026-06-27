WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    c.c_region,
    order_info.order_year,
    p.p_category,
    SUM(order_info.lo_extendedprice * (1 - order_info.lo_discount / 100.0)) AS total_sales,
    SUM(order_info.lo_revenue - order_info.lo_supplycost) AS total_profit,
    AVG(date_diff('day', CAST(order_info.order_date AS date), CAST(order_info.commit_date AS date))) AS avg_lead_days,
    COUNT(DISTINCT order_info.lo_orderkey) AS order_cnt
FROM order_info
JOIN customer c
    ON order_info.lo_custkey = c.c_custkey
JOIN part p
    ON order_info.lo_partkey = p.p_partkey
JOIN supplier s
    ON order_info.lo_suppkey = s.s_suppkey
WHERE order_info.order_year = '1995'
  AND c.c_region = 'AMERICA'
  AND p.p_category = 'MFGR#12'
GROUP BY c.c_region,
         order_info.order_year,
         p.p_category
ORDER BY total_sales DESC
LIMIT 10
