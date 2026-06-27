WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month,
        d_commit.d_date AS commit_date,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND lo.lo_shipmode = 'AIR'
),
agg AS (
    SELECT
        order_year,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        SUM(lo_quantity) AS total_quantity,
        COUNT(*) AS line_count
    FROM order_dim
    GROUP BY order_year, c_region, p_category
)
SELECT
    order_year,
    c_region,
    p_category,
    total_revenue,
    avg_discount,
    total_quantity,
    line_count,
    ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 10
