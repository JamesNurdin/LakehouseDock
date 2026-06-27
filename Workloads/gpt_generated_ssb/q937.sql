WITH lo_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        c.c_region AS c_region,
        p.p_category AS p_category,
        s.s_region AS s_region,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year
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
)
SELECT
    c_region,
    p_category,
    s_region,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount
FROM lo_enriched
WHERE order_year = '1995'
  AND commit_year = '1995'
  AND lo_shipmode = 'AIR'
GROUP BY
    c_region,
    p_category,
    s_region
ORDER BY total_revenue DESC
LIMIT 100
