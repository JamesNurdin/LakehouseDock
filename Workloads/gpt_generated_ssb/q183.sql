WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        c.c_region AS region,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        CAST(d_order.d_daynuminyear AS integer) AS order_daynum,
        CAST(d_commit.d_daynuminyear AS integer) AS commit_daynum
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    WHERE d_order.d_year = '1998'
      AND c.c_region = 'ASIA'
      AND d_order.d_year = d_commit.d_year
)
SELECT
    region,
    order_year,
    order_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    AVG(commit_daynum - order_daynum) AS avg_lead_time_days,
    COUNT(DISTINCT lo_custkey) AS distinct_customers,
    COUNT(*) AS order_count
FROM order_details
GROUP BY region, order_year, order_month
ORDER BY total_revenue DESC
LIMIT 100
