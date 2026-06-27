-- Revenue, profit and supplier ranking for orders placed in 1994 with commit dates in 1995 or later
WITH order_filtered AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_tax,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_date AS commit_date,
        c.c_region,
        p.p_category,
        s.s_name,
        s.s_region AS supplier_region
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
    WHERE d_order.d_year = '1994'
      AND CAST(d_commit.d_year AS integer) >= 1995
      AND CAST(d_commit.d_year AS integer) >= CAST(d_order.d_year AS integer)
),

supplier_agg AS (
    SELECT
        of.c_region,
        of.p_category,
        of.s_name,
        of.supplier_region,
        of.order_year,
        SUM(of.lo_revenue) AS total_revenue,
        SUM(of.lo_revenue - of.lo_supplycost) AS total_profit,
        SUM(of.lo_quantity) AS total_quantity
    FROM order_filtered of
    GROUP BY of.c_region, of.p_category, of.s_name, of.supplier_region, of.order_year
)
SELECT
    sa.c_region,
    sa.p_category,
    sa.order_year,
    sa.s_name,
    sa.supplier_region,
    sa.total_revenue,
    sa.total_profit,
    RANK() OVER (PARTITION BY sa.c_region, sa.p_category, sa.order_year ORDER BY sa.total_revenue DESC) AS revenue_rank
FROM supplier_agg sa
WHERE sa.total_revenue > 0
ORDER BY sa.c_region, sa.p_category, sa.order_year, revenue_rank
LIMIT 200
