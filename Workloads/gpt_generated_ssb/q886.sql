/*
  Revenue and average order‑to‑commit lead time by supplier region and part category for the year 1995.
*/
WITH lo_prepared AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_supplycost,
        CAST(lo.lo_orderdate AS varchar) AS order_date_key,
        CAST(lo.lo_commitdate AS varchar) AS commit_date_key
    FROM lineorder lo
)
SELECT
    d_ord.d_year AS order_year,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo_prepared.lo_extendedprice * (1 - lo_prepared.lo_discount / 100.0)) AS revenue,
    AVG(date_diff('day', date(d_ord.d_date), date(d_com.d_date))) AS avg_lead_time_days
FROM lo_prepared
JOIN dim_date d_ord ON lo_prepared.order_date_key = d_ord.d_datekey   -- lineorder.lo_orderdate = dim_date.d_datekey
JOIN dim_date d_com ON lo_prepared.commit_date_key = d_com.d_datekey   -- lineorder.lo_commitdate = dim_date.d_datekey
JOIN supplier s ON lo_prepared.lo_suppkey = s.s_suppkey               -- lineorder.lo_suppkey = supplier.s_suppkey
JOIN part p ON lo_prepared.lo_partkey = p.p_partkey                 -- lineorder.lo_partkey = part.p_partkey
WHERE d_ord.d_year = '1995'
GROUP BY d_ord.d_year, s.s_region, p.p_category
ORDER BY revenue DESC
LIMIT 10
