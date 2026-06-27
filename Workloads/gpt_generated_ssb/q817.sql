WITH filtered_date AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_date BETWEEN '1995-01-01' AND '1995-12-31'
)
SELECT
    filtered_date.d_year,
    customer.c_region,
    part.p_category,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_supplycost) AS total_supplycost,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    AVG(lineorder.lo_discount) AS avg_discount,
    SUM(lineorder.lo_quantity) AS total_quantity
FROM lineorder
JOIN filtered_date
    ON lineorder.lo_orderdate = CAST(filtered_date.d_datekey AS INTEGER)
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE part.p_category = 'MFGR#12'
GROUP BY filtered_date.d_year, customer.c_region, part.p_category
ORDER BY total_revenue DESC
LIMIT 10
