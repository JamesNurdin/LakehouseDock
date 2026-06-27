WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year,
        cd.d_date AS commit_date,
        c.c_region AS region,
        p.p_category AS category
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE s.s_region = 'ASIA'
      AND p.p_category IN ('MFGR#12', 'MFGR#13')
      AND CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
)
SELECT
    order_year,
    region,
    category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(DATE_DIFF('day', CAST(commit_date AS DATE), CAST(order_date AS DATE))) AS avg_days_between_commit_and_order
FROM lo_joined
GROUP BY order_year, region, category
ORDER BY total_revenue DESC
