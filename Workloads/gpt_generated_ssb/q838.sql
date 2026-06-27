WITH order_data AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS part_category
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND CAST(d_order.d_date AS date) >= DATE '1997-01-01'
      AND CAST(d_order.d_date AS date) <= DATE '1997-12-31'
)
SELECT
    d_year AS order_year,
    customer_region,
    supplier_region,
    part_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_days_to_commit
FROM order_data
GROUP BY d_year, customer_region, supplier_region, part_category
ORDER BY total_revenue DESC
LIMIT 100
