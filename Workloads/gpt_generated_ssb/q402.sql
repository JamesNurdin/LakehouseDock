WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_supplycost
    FROM lineorder lo
    WHERE lo.lo_revenue > 0
)
SELECT
    d_order.d_year AS order_year,
    s.s_region AS supplier_region,
    sum(lo.lo_revenue) AS total_revenue,
    avg(lo.lo_discount) AS avg_discount,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    avg(
        CAST(d_commit.d_daynuminyear AS integer) - CAST(d_order.d_daynuminyear AS integer)
    ) AS avg_lead_time_days
FROM order_data lo
JOIN dim_date d_order
    ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
JOIN dim_date d_commit
    ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'ASIA'
GROUP BY d_order.d_year, s.s_region
ORDER BY total_revenue DESC
