WITH lo_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_shipmode,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    c.c_region,
    s.s_region,
    lo_enriched.order_year,
    p.p_category,
    SUM(lo_enriched.lo_revenue) AS total_revenue,
    SUM(lo_enriched.lo_revenue - lo_enriched.lo_supplycost) AS total_profit,
    AVG(lo_enriched.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_enriched.lo_orderkey) AS order_cnt
FROM lo_enriched
JOIN customer c
    ON lo_enriched.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo_enriched.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo_enriched.lo_partkey = p.p_partkey
GROUP BY
    c.c_region,
    s.s_region,
    lo_enriched.order_year,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 100
