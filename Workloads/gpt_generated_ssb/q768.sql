/*
  Revenue, profit and average lead‑time (days between order and commit) per year
  for the MFGR#12 part category and customers in the ASIA region.
*/
WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        od.d_year               AS order_year,
        od.d_date               AS order_date,
        cd.d_date               AS commit_date,
        c.c_region,
        p.p_category
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey   -- order date surrogate key
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey   -- commit date surrogate key
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year IN ('1994', '1995')
      AND p.p_category = 'MFGR#12'
      AND c.c_region = 'ASIA'
)
SELECT
    order_year,
    c_region,
    p_category,
    COUNT(*)                                                   AS order_cnt,
    SUM(lo_revenue)                                            AS total_revenue,
    SUM(lo_revenue - lo_supplycost)                            AS total_profit,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE)))
                                                               AS avg_lead_time_days
FROM order_info
GROUP BY order_year, c_region, p_category
ORDER BY order_year, total_revenue DESC
