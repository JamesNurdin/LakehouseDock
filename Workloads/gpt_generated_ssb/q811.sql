WITH orders_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        d_order.d_year AS order_year,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d_order.d_year = '1995'
      AND CAST(d_commit.d_year AS INTEGER) >= CAST(d_order.d_year AS INTEGER)
)
SELECT
    order_year,
    supplier_region,
    customer_region,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
    CAST(SUM(lo_revenue) - SUM(lo_supplycost) AS DOUBLE) / NULLIF(SUM(lo_revenue), 0) AS profit_margin,
    AVG(lo_discount) AS avg_discount
FROM orders_enriched
GROUP BY order_year, supplier_region, customer_region
ORDER BY total_revenue DESC
LIMIT 20
