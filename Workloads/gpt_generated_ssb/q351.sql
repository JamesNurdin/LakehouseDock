WITH lo_base AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_revenue,
        lo_supplycost,
        lo_discount
    FROM lineorder
)
SELECT
    od.d_year AS year,
    c.c_region AS cust_region,
    s.s_region AS supp_region,
    p.p_category AS part_category,
    SUM(lo_base.lo_revenue) AS total_revenue,
    SUM(lo_base.lo_supplycost) AS total_supplycost,
    SUM(lo_base.lo_revenue - lo_base.lo_supplycost) AS total_profit,
    AVG(lo_base.lo_discount) AS avg_discount,
    AVG(lo_base.lo_commitdate - lo_base.lo_orderdate) AS avg_commit_lag_days
FROM lo_base
JOIN dim_date od
    ON CAST(od.d_datekey AS integer) = lo_base.lo_orderdate
JOIN customer c
    ON lo_base.lo_custkey = c.c_custkey
JOIN part p
    ON lo_base.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo_base.lo_suppkey = s.s_suppkey
WHERE od.d_year IN ('1995', '1996')
GROUP BY od.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
