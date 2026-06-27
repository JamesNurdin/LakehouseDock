WITH agg AS (
    SELECT
        order_date.d_year AS order_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS product_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        AVG(date_diff('day', CAST(order_date.d_date AS date), CAST(commit_date.d_date AS date))) AS avg_lag_days,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN dim_date order_date
      ON CAST(order_date.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date commit_date
      ON CAST(commit_date.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    WHERE order_date.d_year BETWEEN '1995' AND '1997'
    GROUP BY
        order_date.d_year,
        c.c_region,
        s.s_region,
        p.p_category
)
SELECT
    order_year,
    customer_region,
    supplier_region,
    product_category,
    total_revenue,
    total_profit,
    avg_discount,
    avg_lag_days,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY order_year, customer_region ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 100
