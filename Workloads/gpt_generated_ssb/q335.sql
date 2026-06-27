WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        od.d_year AS od_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        s.s_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
      AND c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_category = 'MFGR#1'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    od_year,
    s_region,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(date_diff('day', DATE(order_date), DATE(commit_date))) AS avg_lead_time_days,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_data
GROUP BY od_year, s_region
ORDER BY od_year, s_region
