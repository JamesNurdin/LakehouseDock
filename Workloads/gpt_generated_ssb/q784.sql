WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_discount,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        CAST(d_order.d_date AS DATE) AS order_date,
        CAST(d_commit.d_date AS DATE) AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE d_order.d_year = '1995'
)
SELECT
    order_year,
    order_month,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', order_date, commit_date)) AS avg_days_to_commit,
    SUM(lo_revenue) / SUM(lo_quantity) AS avg_price_per_item
FROM order_commit
GROUP BY order_year, order_month
ORDER BY order_year, order_month
