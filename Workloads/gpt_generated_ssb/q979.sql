WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        d_ord.d_year,
        d_ord.d_date AS order_date,
        d_com.d_date AS commit_date,
        p.p_category,
        s.s_region,
        c.c_mktsegment
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(d_ord.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_com
        ON CAST(d_com.d_datekey AS integer) = lo.lo_commitdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_shipmode = 'AIR'
      AND s.s_region = 'ASIA'
      AND c.c_mktsegment = 'AUTOMOBILE'
      AND d_ord.d_year = '1998'
)
SELECT
    order_info.d_year AS order_year,
    order_info.p_category AS product_category,
    SUM(order_info.lo_revenue) AS total_revenue,
    SUM(order_info.lo_revenue - order_info.lo_supplycost) AS total_profit,
    AVG(order_info.lo_discount) AS avg_discount,
    AVG(date_diff('day',
                  CAST(order_info.order_date AS DATE),
                  CAST(order_info.commit_date AS DATE))) AS avg_lead_time_days,
    COUNT(DISTINCT order_info.lo_orderkey) AS distinct_orders
FROM order_info
GROUP BY order_info.d_year, order_info.p_category
ORDER BY total_revenue DESC
LIMIT 20
