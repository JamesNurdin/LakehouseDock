WITH lo_dates AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        CAST(lo_orderdate AS VARCHAR) AS order_date_key,
        CAST(lo_commitdate AS VARCHAR) AS commit_date_key
    FROM lineorder
),
joined_data AS (
    SELECT
        lo_dates.lo_orderkey,
        lo_dates.lo_revenue,
        lo_dates.lo_supplycost,
        lo_dates.lo_discount,
        c.c_region,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        p.p_category,
        s.s_region AS supplier_region
    FROM lo_dates
    JOIN dim_date d_order
        ON lo_dates.order_date_key = d_order.d_datekey
    JOIN dim_date d_commit
        ON lo_dates.commit_date_key = d_commit.d_datekey
    JOIN customer c
        ON lo_dates.lo_custkey = c.c_custkey
    JOIN part p
        ON lo_dates.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo_dates.lo_suppkey = s.s_suppkey
)
SELECT
    order_year,
    c_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM joined_data
WHERE p_category = 'MFGR#12'
  AND supplier_region = 'ASIA'
  AND order_year = '1996'
GROUP BY order_year, c_region
ORDER BY total_revenue DESC
