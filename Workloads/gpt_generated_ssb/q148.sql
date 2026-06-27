WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_revenue,
        lo.lo_discount,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_order.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    c_region,
    p_category,
    supplier_region,
    order_year,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_days_to_commit,
    SUM(lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM order_info
GROUP BY c_region, p_category, supplier_region, order_year
ORDER BY total_revenue DESC
LIMIT 10
