/*
  Analytical query on the SSB benchmark using Trino.
  For each year, market segment, and part category, it returns the top 3 suppliers by revenue.
  The query joins the fact table (lineorder) to all dimension tables using the allowed join keys,
  filters orders and commits to the year 1995 via the dim_date.d_date column, aggregates revenue,
  profit, discount and order count, then ranks suppliers within each (year, segment, category) group.
*/
WITH order_join AS (
    SELECT
        d_order.d_year AS d_year,
        c.c_mktsegment,
        p.p_category,
        s.s_name,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderkey
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
      AND CAST(d_commit.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
aggregated AS (
    SELECT
        d_year,
        c_mktsegment,
        p_category,
        s_name,
        sum(lo_revenue) AS total_revenue,
        sum(lo_revenue - lo_supplycost) AS total_profit,
        avg(lo_discount) AS avg_discount,
        count(DISTINCT lo_orderkey) AS num_orders
    FROM order_join
    GROUP BY d_year, c_mktsegment, p_category, s_name
),
ranked AS (
    SELECT
        d_year,
        c_mktsegment,
        p_category,
        s_name,
        total_revenue,
        total_profit,
        avg_discount,
        num_orders,
        row_number() OVER (
            PARTITION BY d_year, c_mktsegment, p_category
            ORDER BY total_revenue DESC
        ) AS supplier_rank
    FROM aggregated
)
SELECT
    d_year,
    c_mktsegment,
    p_category,
    s_name,
    total_revenue,
    total_profit,
    avg_discount,
    num_orders,
    supplier_rank
FROM ranked
WHERE supplier_rank <= 3
ORDER BY d_year, c_mktsegment, p_category, supplier_rank
