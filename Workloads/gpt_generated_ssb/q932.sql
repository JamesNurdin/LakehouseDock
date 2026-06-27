WITH lineorder_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
      AND lo.lo_discount > 5
      AND d_commit.d_year <= '1995'
)
SELECT
    order_year,
    s_region AS supplier_region,
    p_category AS part_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    COUNT(*) AS line_count
FROM lineorder_enriched
GROUP BY
    order_year,
    s_region,
    p_category
ORDER BY total_revenue DESC
LIMIT 100
