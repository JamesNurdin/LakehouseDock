WITH order_data AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        CAST(d_order.d_year AS INTEGER) - CAST(d_commit.d_year AS INTEGER) AS year_gap,
        c.c_region,
        p.p_category,
        p.p_brand1
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
    WHERE d_order.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    order_year,
    commit_year,
    year_gap,
    c_region,
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM order_data
GROUP BY order_year, commit_year, year_gap, c_region, p_category, p_brand1
ORDER BY total_revenue DESC
LIMIT 10
